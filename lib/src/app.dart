import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/app_settings_controller.dart';
import 'core/theme/finance_theme.dart';
import 'features/home/home_screen.dart';

class FinanceApp extends ConsumerWidget {
  const FinanceApp({
    super.key,
    required this.settingsController,
  });

  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Finance Compass',
          debugShowCheckedModeBanner: false,
          theme: buildFinanceTheme(settingsController.themeStyle),
          home: HomeScreen(settingsController: settingsController),
        );
      },
    );
  }
}
