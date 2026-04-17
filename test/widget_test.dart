import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/src/core/data/finance_repository.dart';
import 'package:finance_app/src/core/settings/app_settings_controller.dart';
import 'package:finance_app/src/features/home/home_screen.dart';

void main() {
  testWidgets('app renders dashboard title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const FinanceAppTestHarness(),
    );
    await tester.pumpAndSettle();

    expect(find.text('总览'), findsOneWidget);
  });
}

class FinanceAppTestHarness extends StatelessWidget {
  const FinanceAppTestHarness({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = AppSettingsController();
    return MaterialApp(
      home: HomeScreen(
        repositoryFuture: Future.value(FinanceRepository.preview()),
        settingsController: settingsController,
      ),
    );
  }
}
