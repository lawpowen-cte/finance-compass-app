import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/settings/app_theme_style.dart';
import '../../core/theme/finance_theme.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settingsController,
    required this.onLoadExampleData,
    required this.onExportJsonBytes,
    required this.onExportAiSummaryBytes,
    required this.onExportFuturePlanningBytes,
    required this.onImportJson,
    required this.onPreviewImportJson,
  });

  final AppSettingsController settingsController;
  final Future<void> Function() onLoadExampleData;
  final Future<Uint8List> Function() onExportJsonBytes;
  final Future<Uint8List> Function() onExportAiSummaryBytes;
  final Future<Uint8List> Function() onExportFuturePlanningBytes;
  final Future<void> Function(String path) onImportJson;
  final Future<ImportPreview> Function(String path) onPreviewImportJson;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBusy = false;

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

  Future<void> _exportJson({
    required String fileName,
    required Future<Uint8List> Function() bytesBuilder,
    required String successLabel,
  }) async {
    await _runBusyTask(() async {
      final bytes = await bytesBuilder();
      if (bytes.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导出内容为空，未保存文件。')));
        return;
      }

      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: bytes,
        fileExtension: 'json',
        mimeType: MimeType.custom,
        customMimeType: 'application/json',
      );

      if (!mounted) {
        return;
      }

      if (savedPath == null || savedPath.trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有完成保存。')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successLabel\n$savedPath\n大小 ${bytes.length} bytes')),
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
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出内容为空，未保存文件。')),
        );
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

      if (savedPath == null || savedPath.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有完成保存。')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successLabel\n$savedPath\n大小 ${bytes.length} bytes')),
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

      final preview = await widget.onPreviewImportJson(path);
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
          const SnackBar(content: Text('这个 JSON 没有可导入的数据，可能是旧版空导出文件。')),
        );
        return;
      }

      final shouldImport = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
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
              );
            },
          ) ??
          false;

      if (!shouldImport || !mounted) {
        return;
      }

      await widget.onImportJson(path);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入完成：${preview.accounts} 账户，${preview.categories} 类别，'
            '${preview.budgets} 预算，${preview.transactions} 交易，'
            '${preview.assetSnapshots} 快照。',
          ),
        ),
      );
    });
  }

  Future<void> _loadExampleData() async {
    final confirmed =
            await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
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
                );
              },
            ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await _runBusyTask(() async {
      await widget.onLoadExampleData();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('示例资料已写入。')));
    });
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
                  final selected = style == widget.settingsController.themeStyle;
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
                                  bytesBuilder: widget.onExportJsonBytes,
                                  successLabel: 'JSON 已保存到',
                                ),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('导出 JSON'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBusy
                            ? null
                            : () => _exportJson(
                                  fileName: 'finance_compass_ai_summary',
                                  bytesBuilder: widget.onExportAiSummaryBytes,
                                  successLabel: 'AI 摘要已保存到',
                                ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('导出 AI 摘要'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBusy
                            ? null
                            : () => _exportCsv(
                                  fileName: 'finance_compass_future_planning',
                                  bytesBuilder: widget.onExportFuturePlanningBytes,
                                  successLabel: '未来规划表已保存到',
                                ),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('导出未来规划表'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '完整 JSON 会包含账户、类别、预算、交易、资产快照和应用元资料。AI 摘要只保留汇总数据。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '资料导入',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isBusy ? null : _pickAndImportJson,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('导入 JSON'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '导入前会先显示预览，并在确认后覆盖当前资料。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
