import 'dart:convert';

import '../database/app_database.dart';
import '../utils/currency_formatter.dart';

/// 货币转换与汇率管理服务。
///
/// 负责解析、存储和查询汇率数据，提供跨币种金额转换。
/// 所有汇率均以 [baseCurrency] 为基准。
class CurrencyService {
  CurrencyService({
    required this.database,
    required Map<String, String> metaValues,
  }) : _metaValues = metaValues;

  static const _exchangeRatesMetaKey = 'exchange_rates_to_base_json';
  static const _currencyPriorityMetaKey = 'currency_priority_json';

  final AppDatabase database;
  final Map<String, String> _metaValues;

  // ---------------------------------------------------------------------------
  // 按优先级排列的货币列表
  // ---------------------------------------------------------------------------

  /// 按用户偏好排序的货币列表（首项为基准货币）。
  ///
  /// 从 `_metaValues` 读取用户自定义顺序，
  /// 若无记录则使用 [supportedCurrencies] 默认顺序。
  List<String> get currencyPriority {
    final raw = _metaValues[_currencyPriorityMetaKey];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final ordered = decoded
              .map((item) => normalizeCurrency('$item'))
              .where(supportedCurrencies.contains)
              .toSet()
              .toList();
          return [
            ...ordered,
            ...supportedCurrencies.where((item) => !ordered.contains(item)),
          ];
        }
      } catch (_) {
        // Keep the default order if metadata was edited manually.
      }
    }
    return List.unmodifiable(supportedCurrencies);
  }

  /// 当前基准货币（[currencyPriority] 的首项）。
  String get baseCurrency => currencyPriority.first;

  /// 辅助货币（[currencyPriority] 的第二项），若仅有一种货币则为 `null`。
  String? get secondaryCurrency {
    final priority = currencyPriority;
    return priority.length < 2 ? null : priority[1];
  }

  // ---------------------------------------------------------------------------
  // 汇率
  // ---------------------------------------------------------------------------

  /// 所有货币到基准货币的汇率映射。
  ///
  /// 若元数据中未存储，则使用默认汇率。
  Map<String, double> get exchangeRatesToBase {
    final raw = _metaValues[_exchangeRatesMetaKey];
    if (raw == null || raw.trim().isEmpty) {
      return _defaultRatesForBase(baseCurrency);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final rates = {
          for (final entry in decoded.entries)
            normalizeCurrency(entry.key): entry.value is num
                ? (entry.value as num).toDouble()
                : double.tryParse('${entry.value}') ?? 1,
        };
        return normalizedExchangeRatesToBase(
          rates,
          baseCurrency: baseCurrency,
        );
      }
    } catch (_) {
      // Fall back to defaults if older metadata was edited manually.
    }
    return _defaultRatesForBase(baseCurrency);
  }

  /// 持久化更新汇率与货币优先级，返回更新后的 [CurrencyService]。
  Future<CurrencyService> updateExchangeRates(
    Map<String, double> ratesToBase,
    List<String> currencyPriority,
  ) async {
    final ordered = _normalizeCurrencyPriority(currencyPriority);
    final normalized = normalizedExchangeRatesToBase(
      ratesToBase,
      baseCurrency: ordered.first,
    );
    await database.setMetaValue(_exchangeRatesMetaKey, jsonEncode(normalized));
    await database.setMetaValue(_currencyPriorityMetaKey, jsonEncode(ordered));
    return CurrencyService(
      database: database,
      metaValues: {
        ..._metaValues,
        _exchangeRatesMetaKey: jsonEncode(normalized),
        _currencyPriorityMetaKey: jsonEncode(ordered),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 金额转换
  // ---------------------------------------------------------------------------

  /// 将 [amount] 从 [fromCurrency] 转换为 [toCurrency]。
  double convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    return convertCurrencyAmount(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      ratesToBase: exchangeRatesToBase,
      baseCurrency: baseCurrency,
    );
  }

  /// 将 [amount] 从 [currency] 转换为基准货币。
  double convertToBase(double amount, String currency) {
    return convertAmount(
      amount: amount,
      fromCurrency: currency,
      toCurrency: baseCurrency,
    );
  }

  /// 将 [amount] 从基准货币转换为 [currency]。
  double convertFromBase(double amount, String currency) {
    return convertAmount(
      amount: amount,
      fromCurrency: baseCurrency,
      toCurrency: currency,
    );
  }

  /// 返回 "≈ 目标货币 金额" 格式的转换提示。
  ///
  /// 若当前币种即为基准币种，则显示到辅助货币的转换；
  /// 否则显示到基准货币的转换。
  String conversionHintForAmount(double amount, String currency) {
    final normalized = normalizeCurrency(currency);
    final targetCurrency =
        normalized == baseCurrency ? secondaryCurrency : baseCurrency;
    if (targetCurrency == null || targetCurrency == normalized) {
      return '';
    }
    return formatConversionHint(
      amount: amount,
      fromCurrency: normalized,
      toCurrency: targetCurrency,
      ratesToBase: exchangeRatesToBase,
      baseCurrency: baseCurrency,
    );
  }

  // ---------------------------------------------------------------------------
  // 私有辅助
  // ---------------------------------------------------------------------------

  List<String> _normalizeCurrencyPriority(List<String> currencies) {
    final ordered = currencies
        .map(normalizeCurrency)
        .where(supportedCurrencies.contains)
        .toSet()
        .toList();
    return [
      ...ordered,
      ...supportedCurrencies.where((item) => !ordered.contains(item)),
    ];
  }

  Map<String, double> _defaultRatesForBase(String baseCurrency) {
    final base = normalizeCurrency(baseCurrency);
    final converted = <String, double>{};
    for (final currency in supportedCurrencies) {
      converted[currency] = convertCurrencyAmount(
        amount: 1,
        fromCurrency: currency,
        toCurrency: base,
        ratesToBase: defaultExchangeRatesToBase,
        baseCurrency: baseCurrencyCode,
      );
    }
    converted[base] = 1;
    return normalizedExchangeRatesToBase(converted, baseCurrency: base);
  }
}
