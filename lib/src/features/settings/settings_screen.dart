import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/data/finance_repository.dart';
import '../../core/providers/mutations/account_mutations.dart';
import '../../core/providers/mutations/export_mutations.dart';

import '../../core/settings/app_settings_controller.dart';
import '../../core/settings/app_theme_style.dart';
import '../../core/theme/finance_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.settingsController,
  });
  final FinanceRepository repository;
  final AppSettingsController settingsController;
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBusy = false;
  final _rateControllers = <String, TextEditingController>{};
  var _currencyOrder = <String>[];
  late final TextEditingController _aiBaseUrlController;
  late final TextEditingController _aiApiKeyController;
  late final TextEditingController _aiModelController;

  @override
  void initState() {
    super.initState();
    _syncRateControllers();
    _aiBaseUrlController = TextEditingController(
      text: widget.repository.aiBaseUrl,
    );
    _aiApiKeyController = TextEditingController(
      text: widget.repository.aiApiKey,
    );
    _aiModelController = TextEditingController(
      text: widget.repository.aiModel,
    );
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository.metaValues != widget.repository.metaValues) {
      _syncRateControllers();
      _aiBaseUrlController.text = widget.repository.aiBaseUrl;
      _aiApiKeyController.text = widget.repository.aiApiKey;
      _aiModelController.text = widget.repository.aiModel;
    }
  }

  @override
  void dispose() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    _aiBaseUrlController.dispose();
    _aiApiKeyController.dispose();
    _aiModelController.dispose();
    super.dispose();
  }

  void _syncRateControllers() {
    _currencyOrder = widget.repository.currencyPriority;
    final rates = widget.repository.exchangeRatesToBase;
    for (final currency in supportedCurrencies) {
      final controller = _rateControllers.putIfAbsent(
        currency,
        TextEditingController.new,
      );
      controller.text = (rates[currency] ?? 1).toStringAsFixed(4);
    }
  }

  Future<void> _runBusyTask(Future<void> Function() task) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _saveExchangeRates() async {
    final baseCurrency = _currencyOrder.first;
    final nextRates = <String, double>{baseCurrency: 1};
    for (final currency
        in _currencyOrder.where((item) => item != baseCurrency)) {
      final rate = double.tryParse(_rateControllers[currency]!.text.trim());
      if (rate == null || rate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '请填写有效汇率：1 $currency = ? ${currencyLabel(baseCurrency)}',
            ),
          ),
        );
        return;
      }
      nextRates[currency] = rate;
    }
    await _runBusyTask(() async {
      await ref.read(accountMutationsProvider.notifier).updateExchangeRates(nextRates, _currencyOrder);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('汇率和优先级已更新')),
      );
    });
  }

  void _moveCurrency(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final oldBase = _currencyOrder.first;
      final moved = _currencyOrder.removeAt(oldIndex);
      _currencyOrder.insert(newIndex, moved);
      final newBase = _currencyOrder.first;
      if (oldBase != newBase) {
        _recalculateRateFieldsForBase(newBase);
      }
    });
  }

  void _recalculateRateFieldsForBase(String nextBaseCurrency) {
    for (final currency in supportedCurrencies) {
      final controller = _rateControllers[currency]!;
      if (currency == nextBaseCurrency) {
        controller.text = '1.0000';
        continue;
      }
      final converted = widget.repository.convertAmount(
        amount: 1,
        fromCurrency: currency,
        toCurrency: nextBaseCurrency,
      );
      controller.text = converted.toStringAsFixed(4);
    }
  }

  Future<void> _exportJson({
    required String fileName,
    required Future<Uint8List> Function() bytesBuilder,
    required String successLabel,
    String Function(Uint8List bytes)? validateBytes,
    bool openAfterSave = false,
  }) async {
    await _runBusyTask(() async {
      final bytes = await bytesBuilder();
      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出内容为空，未保存文件。')),
          );
        }
        return;
      }

      String? validationLabel;
      try {
        validationLabel = validateBytes?.call(bytes);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出校验失败：$error')),
          );
        }
        return;
      }

      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        fileExtension: 'json',
        mimeType: MimeType.custom,
        customMimeType: 'application/json',
      );
      if (openAfterSave && savedPath != null && savedPath.trim().isNotEmpty) {
        await OpenFilex.open(
          savedPath,
          type: 'application/json',
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath == null || savedPath.trim().isEmpty
                ? '没有完成保存。'
                : '$successLabel\n$savedPath\n大小 ${bytes.length} bytes'
                    '${validationLabel == null ? '' : '\n$validationLabel'}',
          ),
        ),
      );
    });
  }

  Future<void> _exportCsv({
    required String fileName,
    required Future<Uint8List> Function() bytesBuilder,
    required String successLabel,
  }) async {
    await _runBusyTask(() async {
      final bytes = await bytesBuilder();
      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出内容为空，未保存文件。')),
          );
        }
        return;
      }

      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.custom,
        customMimeType: 'text/csv',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath == null || savedPath.trim().isEmpty
                ? '没有完成保存。'
                : '$successLabel\n$savedPath\n大小 ${bytes.length} bytes',
          ),
        ),
      );
    });
  }

  Future<void> _pickAndImportJson() async {
    await _runBusyTask(() async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty || !mounted) {
        return;
      }

      final preview = await ref.read(exportMutationsProvider.notifier).previewImport(path);
      if (!mounted) {
        return;
      }
      final totalItems = preview.accounts +
          preview.categories +
          preview.budgets +
          preview.transactions +
          preview.assetSnapshots;
      if (totalItems == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('这个 JSON 没有可导入的数据。')),
        );
        return;
      }

      final shouldImport = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('导入预览'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('导出时间: ${preview.exportedAt ?? '-'}'),
                  Text('账户: ${preview.accounts}'),
                  Text('类别: ${preview.categories}'),
                  Text('预算: ${preview.budgets}'),
                  Text('交易: ${preview.transactions}'),
                  Text('资产快照: ${preview.assetSnapshots}'),
                  const SizedBox(height: 12),
                  const Text('导入后会覆盖当前资料。'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('确认导入'),
                ),
              ],
            ),
          ) ??
          false;
      if (!shouldImport || !mounted) {
        return;
      }

      await ref.read(exportMutationsProvider.notifier).importJson(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入完成')),
        );
      }
    });
  }

  Future<void> _loadExampleData() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('写入示例资料'),
            content: const Text('这会覆盖当前资料，并写入示例数据。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    await _runBusyTask(() async {
      await ref.read(exportMutationsProvider.notifier).loadExampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('示例资料已写入。')),
        );
      }
    });
  }

  String _validateFullJsonExport(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 根节点不是对象');
    }
    final accounts = _jsonListCount(decoded, 'accounts');
    final categories = _jsonListCount(decoded, 'categories');
    final budgets = _jsonListCount(decoded, 'budgets');
    final transactions = _jsonListCount(decoded, 'transactions');
    final snapshots = _jsonListCount(decoded, 'asset_snapshots');
    if (decoded['meta'] is! Map<String, dynamic>) {
      throw const FormatException('缺少应用元资料 meta');
    }
    return '校验通过：$accounts 账户，$categories 类别，$budgets 预算，'
        '$transactions 交易，$snapshots 快照。';
  }

  int _jsonListCount(Map<String, dynamic> decoded, String key) {
    final value = decoded[key];
    if (value is List) {
      return value.length;
    }
    throw FormatException('缺少 $key 列表');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settingsController,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ScreenHeader(title: '设置'),
            const SizedBox(height: 16),
            SectionCard(
              title: '主题风格',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppThemeStyle.values.map((style) {
                  final selected =
                      style == widget.settingsController.themeStyle;
                  return _ThemePreviewChip(
                    style: style,
                    label: _themeLabel(style),
                    selected: selected,
                    onTap: () => widget.settingsController.setThemeStyle(style),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '汇率优先级',
              subtitle: '拖动排序：第一个是主币种，第二个是提示用的次币种。',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 224,
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: _currencyOrder.length,
                      onReorder: _moveCurrency,
                      itemBuilder: (context, index) {
                        final currency = _currencyOrder[index];
                        final isBase = index == 0;
                        return ListTile(
                          key: ValueKey(currency),
                          contentPadding: EdgeInsets.zero,
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_indicator),
                          ),
                          title: Text(currencyOptionLabel(currency)),
                          subtitle: Text(
                            isBase
                                ? '主币种：所有总额用这个单位显示'
                                : index == 1
                                    ? '次币种：主币种账户会提示这个换算值'
                                    : '可用于账户和交易',
                          ),
                          trailing: isBase
                              ? const Icon(Icons.star_rounded)
                              : Text('#${index + 1}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._currencyOrder
                      .where((item) => item != _currencyOrder.first)
                      .map((currency) {
                    final base = _currencyOrder.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: _rateControllers[currency],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: '1 $currency = ? ${currencyLabel(base)}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    );
                  }),
                  FilledButton.tonalIcon(
                    onPressed: _isBusy ? null : _saveExchangeRates,
                    icon: const Icon(Icons.currency_exchange_outlined),
                    label: const Text('保存汇率和优先级'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '资料导出',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _isBusy
                            ? null
                            : () => _exportJson(
                                  fileName: 'finance_compass_export',
                                  bytesBuilder: () => ref.read(exportMutationsProvider.notifier).exportJsonBytes(),
                                  successLabel: 'JSON 已保存到',
                                  validateBytes: _validateFullJsonExport,
                                ),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('导出 JSON'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBusy
                            ? null
                            : () => _exportJson(
                                  fileName: 'finance_compass_ai_summary',
                                  bytesBuilder: () => ref.read(exportMutationsProvider.notifier).exportAiSummaryBytes(monthKeys: [monthKeyFromDate(DateTime.now())]),
                                  successLabel: 'AI 摘要已保存到',
                                  openAfterSave: true,
                                ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('导出 AI 摘要'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBusy
                            ? null
                            : () => _exportCsv(
                                  fileName: 'finance_compass_future_planning',
                                  bytesBuilder:
                                      () => ref.read(exportMutationsProvider.notifier).exportFuturePlanningCsvBytes(),
                                  successLabel: '未来规划表已保存到',
                                ),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('导出未来规划表'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '完整 JSON 包含账户、类别、预算、交易、快照和应用元资料；AI 摘要只保留汇总数据。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '资料导入',
              child: FilledButton.tonalIcon(
                onPressed: _isBusy ? null : _pickAndImportJson,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入 JSON'),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '工具',
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : _loadExampleData,
                icon: const Icon(Icons.science_outlined),
                label: const Text('写入示例资料'),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'AI 分析配置',
              subtitle: '配置 MiMo API 以启用智能财务分析',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _aiBaseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _aiApiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _aiModelController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _isBusy
                        ? null
                        : () async {
                            await _runBusyTask(() async {
                              await widget.repository.saveAiConfig(
                                _aiBaseUrlController.text.trim(),
                                _aiApiKeyController.text.trim(),
                                _aiModelController.text.trim(),
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('AI 配置已保存')),
                                );
                              }
                            });
                          },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存 AI 配置'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _themeLabel(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.tide:
        return '潮汐';
      case AppThemeStyle.ocean:
        return '海洋';
      case AppThemeStyle.sky:
        return '晴空';
      case AppThemeStyle.ember:
        return '余烬';
      case AppThemeStyle.forest:
        return '森林';
      case AppThemeStyle.dune:
        return '沙丘';
      case AppThemeStyle.aurora:
        return '极光';
    }
  }
}

class _ThemePreviewChip extends StatelessWidget {
  const _ThemePreviewChip({
    required this.style,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppThemeStyle style;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteForStyle(style);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 104,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: palette.cardTint,
          border: Border.all(
            color: selected ? palette.seed : palette.cardBorderStrong,
            width: selected ? 1.8 : 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.seed.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: palette.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: palette.cardBorderStrong),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.seed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
