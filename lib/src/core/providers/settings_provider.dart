import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_controller.dart';
import '../settings/app_theme_style.dart';

/// Loads and exposes [AppSettingsController] to the widget tree.
///
/// The controller reads its persisted values from the database on first
/// load. Subsequent calls to [setThemeStyle] mutate the controller *and*
/// persist the change, then notify listeners.
class AppSettingsNotifier extends AsyncNotifier<AppSettingsController> {
  @override
  Future<AppSettingsController> build() async {
    final controller = AppSettingsController();
    await controller.load();
    return controller;
  }

  /// Persists a new [AppThemeStyle] and refreshes the provider state.
  Future<void> setThemeStyle(AppThemeStyle style) async {
    final controller = state.valueOrNull;
    if (controller == null) return;
    await controller.setThemeStyle(style);
    // Force a new AsyncData so dependants rebuild.
    state = AsyncData(controller);
  }
}

/// The app-wide settings provider.
///
/// Widgets should watch this as `ref.watch(appSettingsProvider)` and
/// access `.value?.themeStyle` for the current theme.
final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettingsController>(
  AppSettingsNotifier.new,
);
