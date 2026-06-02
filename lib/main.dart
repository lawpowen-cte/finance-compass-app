import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/settings/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsController = AppSettingsController();
  await settingsController.load();
  runApp(
    ProviderScope(
      child: FinanceApp(settingsController: settingsController),
    ),
  );
}
