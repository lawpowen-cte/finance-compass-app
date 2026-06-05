import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// 集成测试：直接测试 AI 分析网关的 HTTP 调用
///
/// 模拟 App 中 AiAnalysisService._buildRequestData → POST /api/analyze 的完整流程
///
/// 运行：flutter test test/ai_analysis_integration_test.dart
void main() {
  const gatewayUrl = 'http://localhost:5000';
  const jsonPath =
      '/home/pwlaw/.hermes/cache/documents/doc_c5f1fd11e5c2_finance_compass.json';
  var integrationReady = false;
  String? skipReason;

  group('AI Analysis 网关集成测试', () {
    setUpAll(() async {
      // 检查网关
      try {
        final resp = await http.get(Uri.parse('$gatewayUrl/health'));
        if (resp.statusCode != 200) {
          skipReason = '网关健康检查失败: HTTP ${resp.statusCode}';
          return;
        }
        print('✅ 网关健康检查通过: ${resp.body}');
      } catch (e) {
        skipReason = '无法连接网关 $gatewayUrl: $e';
        return;
      }

      // 检查 JSON 文件
      if (!File(jsonPath).existsSync()) {
        skipReason = 'JSON 文件不存在: $jsonPath';
        return;
      }
      integrationReady = true;
    });

    test('导入 JSON → 模拟 App 构建请求 → 调用网关 → 返回 HTML', () async {
      if (!integrationReady) {
        markTestSkipped(skipReason ?? 'AI 网关集成测试环境未就绪');
        return;
      }

      // ====== Step 1: 读取并解析 JSON（模拟 App importJsonSnapshot） ======
      print('\n📦 Step 1: 读取 JSON 文件...');
      final raw = await File(jsonPath).readAsString();
      final payload = jsonDecode(raw) as Map<String, dynamic>;

      final accounts = payload['accounts'] as List<dynamic>;
      final transactions = payload['transactions'] as List<dynamic>;
      final categories = payload['categories'] as List<dynamic>;
      final budgets = payload['budgets'] as List<dynamic>;
      final meta = payload['meta'] as Map<String, dynamic>? ?? {};
      final snapshots = payload['asset_snapshots'] as List<dynamic>? ?? [];

      print('   账户: ${accounts.length}');
      print('   交易: ${transactions.length}');
      print('   分类: ${categories.length}');
      print('   预算: ${budgets.length}');

      // ====== Step 2: 模拟 AiAnalysisService._buildRequestData ======
      print('\n📊 Step 2: 构建请求数据（模拟 _buildRequestData）...');
      final now = DateTime.now();
      final currentMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastMonthMonth = now.month == 1 ? 12 : now.month - 1;
      final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
      final lastMonth =
          '$lastMonthYear-${lastMonthMonth.toString().padLeft(2, '0')}';

      // 账户余额
      final accountData = <Map<String, dynamic>>[];
      for (final acc in accounts) {
        if (acc['is_active'] == true) {
          accountData.add({
            'name': acc['name'],
            'type': acc['account_type'],
            'balance': acc['current_balance'],
          });
        }
      }

      // 月度收支（用 transaction_date）
      double incomeCurr = 0, expenseCurr = 0;
      double incomeLast = 0, expenseLast = 0;

      for (final tx in transactions) {
        final txDate = tx['transaction_date'] as String? ?? '';
        if (txDate.isEmpty) continue;
        final month = txDate.substring(0, 7);
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        final type = tx['type'] as String? ?? '';

        if (month == currentMonth) {
          if (type == 'income') incomeCurr += amount;
          if (type == 'expense') expenseCurr += amount;
        } else if (month == lastMonth) {
          if (type == 'income') incomeLast += amount;
          if (type == 'expense') expenseLast += amount;
        }
      }

      // 预算
      final budgetData = <Map<String, dynamic>>[];
      for (final b in budgets) {
        final catId = b['category_id'] as String;
        String catName = catId;
        for (final c in categories) {
          if (c['id'] == catId) {
            catName = c['name'];
            break;
          }
        }
        budgetData.add({
          'category': catName,
          'budget': b['amount'],
          'spent': 0,
        });
      }

      // 目标
      final goalData = <Map<String, dynamic>>[];
      final goalsJson = meta['asset_goals_json'] as String?;
      if (goalsJson != null) {
        final goalList = jsonDecode(goalsJson) as List<dynamic>;
        double totalAssets = 0;
        for (final acc in accounts) {
          totalAssets += (acc['current_balance'] as num?)?.toDouble() ?? 0;
        }
        for (final g in goalList) {
          final target = (g['target_amount'] as num).toDouble();
          final progress = (totalAssets / target * 100);
          goalData.add({
            'name': g['name'],
            'target': target,
            'current': totalAssets,
            'progress': progress.toStringAsFixed(1),
            'is_reached': progress >= 100,
          });
        }
      }

      // 近期交易
      final recentTx = <Map<String, dynamic>>[];
      final txList = transactions.reversed.take(10);
      for (final tx in txList) {
        recentTx.add({
          'date': (tx['transaction_date'] as String).substring(0, 10),
          'type': tx['type'],
          'amount': tx['amount'],
        });
      }

      final requestData = {
        'accounts': accountData,
        'current_month': {
          'income': incomeCurr,
          'expense': expenseCurr,
          'net': incomeCurr - expenseCurr,
        },
        'last_month': {
          'income': incomeLast,
          'expense': expenseLast,
        },
        'budgets': budgetData,
        'goals': goalData,
        'recent_transactions': recentTx,
      };

      print('   当前月: $currentMonth 收入=$incomeCurr 支出=$expenseCurr');
      print('   上月: $lastMonth 收入=$incomeLast 支出=$expenseLast');
      print('   活跃账户: ${accountData.length}');
      print('   目标: ${goalData.length}');

      // ====== Step 3: 调用网关（模拟 AiAnalysisService.generateAnalysis） ======
      print('\n🔄 Step 3: 调用 AI 网关 /api/analyze ...');
      final stopwatch = Stopwatch()..start();

      final response = await http
          .post(
            Uri.parse('$gatewayUrl/api/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'data': requestData}),
          )
          .timeout(const Duration(seconds: 300));

      stopwatch.stop();
      print('   耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('   状态码: ${response.statusCode}');

      // ====== Step 4: 验证结果 ======
      expect(response.statusCode, 200,
          reason: '网关应返回 200，实际: ${response.statusCode} ${response.body}');

      final result = jsonDecode(response.body);
      final html = result['html'] as String;
      final modelUsed = result['model_used'] as String;

      print('   模型: $modelUsed');
      print('   HTML 长度: ${html.length} 字符');

      expect(html, isNotEmpty, reason: 'HTML 不应为空');
      expect(html, contains('<'), reason: 'HTML 应包含 HTML 标签');
      expect(html.length, greaterThan(100), reason: 'HTML 长度应 > 100');
      expect(modelUsed, equals('mimo'), reason: '应使用 mimo 模型');

      print('\n✅ 完整流程测试通过！');
      print('   JSON 导入 → 数据提取 → 构建请求 → 网关调用 → 返回 HTML');

      // 保存结果
      final outputPath = '/tmp/ai_analysis_result.html';
      await File(outputPath).writeAsString(
        '<!DOCTYPE html><html><head><meta charset="utf-8">'
        '<title>AI Analysis Test</title></head>'
        '<body style="font-family:system-ui;max-width:800px;margin:0 auto;padding:20px">'
        '$html</body></html>',
      );
      print('   结果已保存: $outputPath');
    }, timeout: const Timeout(Duration(minutes: 6)));
  });
}
