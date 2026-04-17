import 'package:flutter/material.dart';

import '../database/database_provider.dart';
import 'app_theme_style.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController();

  AppThemeStyle _themeStyle = AppThemeStyle.tide;
  bool _isLoaded = false;

  AppThemeStyle get themeStyle => _themeStyle;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final rawValue = await DatabaseProvider.instance.getMetaValue('theme_style');
    if (rawValue != null) {
      _themeStyle = AppThemeStyle.values.firstWhere(
        (style) => style.name == rawValue,
        orElse: () => AppThemeStyle.tide,
      );
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    _themeStyle = style;
    await DatabaseProvider.instance.setMetaValue('theme_style', style.name);
    notifyListeners();
  }
}
