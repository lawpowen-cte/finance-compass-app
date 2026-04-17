import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/settings/app_settings_controller.dart';
import '../../core/settings/app_theme_style.dart';
import '../../core/theme/finance_theme.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settingsController,
    required this.onLoadExampleData,
    required this.onExportJson,
    required this.onImportJson,
  });

  final AppSettingsController settingsController;
  final Future<void> Function() onLoadExampleData;
  final Future<String> Function() onExportJson;
  final Future<void> Function(String path) onImportJson;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenHeader(title: '设置'),
        const SizedBox(height: 16),
        SectionCard(
          title: '主题风格',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppThemeStyle.values.map((style) {
              final palette = paletteForStyle(style);
              final selected = settingsController.themeStyle == style;
              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => settingsController.setThemeStyle(style),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 180,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected ? palette.seed : Colors.transparent,
                      width: 2,
                    ),
                    gradient: LinearGradient(colors: palette.gradient),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        style.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _description(style),
                        style: const TextStyle(color: Colors.white, height: 1.3),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '数据',
          subtitle: '导入 JSON 会覆盖当前本地数据',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: () async {
                  await onLoadExampleData();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('示例数据已导入')),
                  );
                },
                icon: const Icon(Icons.dataset_outlined),
                label: const Text('Set Example Data'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final path = await onExportJson();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('JSON 已导出：$path')),
                  );
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('导出 JSON'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['json'],
                  );
                  final path = result?.files.single.path;
                  if (path == null) {
                    return;
                  }
                  await onImportJson(path);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON 已导入并恢复')),
                  );
                },
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入 JSON'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _description(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.tide:
        return '沉静潮汐';
      case AppThemeStyle.ocean:
        return '深海蓝调';
      case AppThemeStyle.sky:
        return '晴空浅蓝';
      case AppThemeStyle.ember:
        return '暖阳橙光';
      case AppThemeStyle.forest:
        return '森林绿意';
      case AppThemeStyle.dune:
        return '沙丘暖米';
      case AppThemeStyle.aurora:
        return '极光暮彩';
    }
  }
}
