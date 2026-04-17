import 'package:flutter/material.dart';

import 'core/settings/app_settings_controller.dart';
import 'core/theme/finance_theme.dart';
import 'features/home/home_screen.dart';

class FinanceApp extends StatelessWidget {
  const FinanceApp({
    super.key,
    required this.settingsController,
  });

  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Finance App',
          debugShowCheckedModeBanner: false,
          theme: buildFinanceTheme(settingsController.themeStyle),
          home: HomeScreen(settingsController: settingsController),
        );
      },
    );
  }
}
