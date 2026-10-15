import 'package:aaj_kya_pakayen/data/providers.dart';
import 'package:aaj_kya_pakayen/domain/entities/app_settings.dart';
import 'package:aaj_kya_pakayen/domain/enums/time_budget.dart';
import 'package:aaj_kya_pakayen/features/settings/settings_controller.dart';
import 'package:aaj_kya_pakayen/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class _MockActions extends Mock implements SettingsActions;

void main() {
  late _MockActions actions;

  setUpAll(() => registerFallbackValue(TimeBudget.normal));

  setUp(() {
    actions = _MockActions();
    when(() => actions.setLanguage(any())).thenAnswer((_) async {});
    when(() => actions.setHouseholdSize(any())).thenAnswer((_) async {});
    when(() => actions.setRepeatWindow(any())).thenAnswer((_) async {});
    when(() => actions.setTimeBudget(any())).thenAnswer((_) async {});
    when(() => actions.setReminderEnabled(enabled: any(named: 'enabled')))
        .thenAnswer((_) async => true);
    when(() => actions.setReminderTime(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester, {
    AppSettings settings = const AppSettings(),
    Locale locale = english,
  }) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWithValue(AsyncData(settings)),
          settingsActionsProvider.overrideWithValue(actions),
        ],
        child: const SettingsScreen(),
      ).wrapInApp(locale: locale),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('switches the language', (tester) async {
    await pump(tester);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'اردو'));
    verify(() => actions.setLanguage('ur')).called(1);
  });

  testWidgets('steps household size and repeat window', (tester) async {
    await pump(tester);

    expect(find.text('4 people'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('More people'));
    verify(() => actions.setHouseholdSize(5)).called(1);
    await tapVisible(tester, find.byTooltip('Fewer people'));
    verify(() => actions.setHouseholdSize(3)).called(1);

    expect(find.text('7 days'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('More days'));
    verify(() => actions.setRepeatWindow(8)).called(1);
  });

  testWidgets('limits disable the stepper buttons', (tester) async {
    await pump(
      tester,
      settings: const AppSettings(householdSize: 1, repeatWindowDays: 14),
    );

    await tapVisible(tester, find.byTooltip('Fewer people'));
    await tapVisible(tester, find.byTooltip('More days'));
    verifyNever(() => actions.setHouseholdSize(any()));
    verifyNever(() => actions.setRepeatWindow(any()));
  });

  testWidgets('chooses a time budget', (tester) async {
    await pump(tester);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Up to 30 min'));
    verify(() => actions.setTimeBudget(TimeBudget.quick)).called(1);
  });

  testWidgets('shows Pakistani on and other cuisines as coming soon', (
    tester,
  ) async {
    await pump(tester);

    await tester.scrollUntilVisible(
      find.text('Chinese'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pakistani'), findsOneWidget);
    expect(find.text('Indian'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(3));
  });

  testWidgets('turns the daily reminder on', (tester) async {
    await pump(tester);

    expect(find.text('4:30 PM'), findsOneWidget);
    await tapVisible(tester, find.text('Daily reminder'));
    verify(() => actions.setReminderEnabled(enabled: true)).called(1);
  });

  testWidgets('explains when notifications are not allowed', (tester) async {
    when(() => actions.setReminderEnabled(enabled: any(named: 'enabled')))
        .thenAnswer((_) async => false);
    await pump(tester);

    await tapVisible(tester, find.text('Daily reminder'));
    expect(
      find.textContaining('Notifications are off for this app.'),
      findsOneWidget,
    );
  });

  testWidgets('changes the reminder time', (tester) async {
    await pump(tester, settings: const AppSettings(reminderEnabled: true));

    await tapVisible(tester, find.text('4:30 PM'));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    verify(() => actions.setReminderTime(16 * 60 + 30)).called(1);
  });

  testWidgets('meets tap target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  for (final locale in [urdu, english]) {
    testWidgets('golden (${locale.languageCode})', (tester) async {
      await pump(tester, locale: locale);
      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('goldens/settings_${locale.languageCode}.png'),
      );
    });
  }
}
