import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/core/settings/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsController = AppSettingsController();
  await settingsController.load();
  runApp(FinanceApp(settingsController: settingsController));
}
