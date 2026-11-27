import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_app/app/operator_app.dart';
import 'package:scoreboard_app/display/display_output.dart';
import 'package:scoreboard_app/scoreboard/scoreboard_view.dart';
import 'package:scoreboard_app/l10n/app_language.dart';
import 'package:scoreboard_app/l10n/app_localizations.dart';
import 'package:scoreboard_app/l10n/localized_values.dart';
import 'package:scoreboard_app/operator/clock_card.dart';
import 'package:scoreboard_app/settings/app_settings.dart';
import 'package:scoreboard_app/settings/shortcuts.dart';
import 'package:scoreboard_app/settings/sport_rule.dart';
import 'package:scoreboard_app/storage/app_storage.dart';
import 'package:scoreboard_app/storage/layout_repository.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

OperatorApp _app(AppSettings settings) => OperatorApp(
  settings: settings,
  layouts: LayoutRepository(MemoryStorage()),
  output: const NoDisplayOutput(),
);

class _RecordingOutput extends NoDisplayOutput {
  DisplayMessage? latest;

  @override
  void show(DisplayMessage message) => latest = message;
}

void _useLargeWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('operator updates scoreboard preview', (tester) async {
    _useLargeWindow(tester);

    await tester.pumpWidget(_app(AppSettings()));
    expect(find.byType(ScoreboardView), findsOneWidget);
    expect(find.text('00:00'), findsWidgets);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.textContaining('Timeout').first);
    await tester.pump();
    expect(find.textContaining('TIMEOUT'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('scoreboard view fills larger screens', (tester) async {
    tester.view.physicalSize = const Size(3840, 2160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScoreboardView(
            layout: defaultHandballLayout(),
            values: const {},
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(ColoredBox).last);
    expect(box.width, 3840);
    expect(box.height, 2160);
  });

  testWidgets('window title follows the language', (tester) async {
    _useLargeWindow(tester);
    final titles = <String>[];
    final settings = AppSettings();

    await tester.pumpWidget(
      OperatorApp(
        settings: settings,
        layouts: LayoutRepository(MemoryStorage()),
        output: const NoDisplayOutput(),
        onTitleChanged: titles.add,
      ),
    );
    settings.setLanguage(AppLanguage.de);
    await tester.pump();

    expect(titles, ['Scoreboard', 'Anzeigetafel']);
  });

  testWidgets('changing language updates Flutter and display localizations', (
    tester,
  ) async {
    _useLargeWindow(tester);
    final storage = MemoryStorage();
    final settings = AppSettings(storage: storage);
    final output = _RecordingOutput();
    await tester.pumpWidget(
      OperatorApp(
        settings: settings,
        layouts: LayoutRepository(MemoryStorage()),
        output: output,
      ),
    );
    final context = tester.element(find.byType(ClockCard));
    final englishCancel = MaterialLocalizations.of(context).cancelButtonLabel;
    expect(output.latest!.values['period.label'], '1st half');

    settings.setLanguage(AppLanguage.de);
    await tester.pumpAndSettle();
    final germanContext = tester.element(find.byType(ClockCard));
    expect(Localizations.localeOf(germanContext), const Locale('de'));
    expect(
      MaterialLocalizations.of(germanContext).cancelButtonLabel,
      isNot(englishCancel),
    );
    expect(output.latest!.values['period.label'], '1. Halbzeit');
    expect((await AppSettings.load(storage)).language, AppLanguage.de);

    settings.setLanguage(AppLanguage.en);
    await tester.pumpAndSettle();
    expect(output.latest!.values['period.label'], '1st half');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('language settings update the open settings pages', (
    tester,
  ) async {
    _useLargeWindow(tester);
    await tester.pumpWidget(_app(AppSettings()));
    await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(find.text('Sprache'), findsOneWidget);
    Navigator.of(tester.element(find.text('Sprache'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('Sprache'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'generated messages localize placeholders, plural forms and model labels',
    () {
      final en = lookupAppLocalizations(const Locale('en'));
      final de = lookupAppLocalizations(const Locale('de'));
      expect(
        en.importedCountFilesRestartTheAppToApplyThem(1),
        'Imported 1 file. Restart the app to apply it.',
      );
      expect(
        de.importedCountFilesRestartTheAppToApplyThem(2),
        '2 Dateien importiert. App neu starten, um sie zu übernehmen.',
      );
      expect(de.useHomeScoreClock, 'Platzhalter: {{home.score}}, {{clock}} …');
      expect(localizedSportName(de, football), 'Fußball');
      expect(
        localizedThemeName(de, ScoreboardTheme.highContrast),
        'Hoher Kontrast',
      );
      expect(localizedShortcutAction(de, ShortcutAction.homePlus), 'Heim +1');
      expect(
        localizedPeriodLabel(de, handball.copyWith(periods: 12), 12),
        'Abschnitt 12',
      );
      expect(localizedPeriodLabel(de, volleyball, 2), 'Satz 2');
      expect(localizedPeriodLabel(de, tableTennis, 3), 'Spiel 3');
      expect(localizedPeriodLabel(de, basketball, 1), 'Q1');
    },
  );
  testWidgets('german language and rebound shortcut', (tester) async {
    _useLargeWindow(tester);

    const keyX = KeyBinding(LogicalKeyboardKey.keyX);
    final settings = AppSettings()
      ..setLanguage(AppLanguage.de)
      ..setBinding(ShortcutAction.homePlus, keyX);
    expect(
      settings.conflict(ShortcutAction.homeMinus, keyX),
      ShortcutAction.homePlus,
    );

    await tester.pumpWidget(_app(settings));
    expect(find.text('Nächste Periode'), findsOneWidget);
    expect(find.text('Start (Leertaste)'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pump();
    expect(find.text('1'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.pump();
    expect(find.text('1'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('theme is applied independent of sport', (tester) async {
    _useLargeWindow(tester);

    final settings = AppSettings()..setTheme('daylight');
    await tester.pumpWidget(_app(settings));
    ScoreboardView view() =>
        tester.widget<ScoreboardView>(find.byType(ScoreboardView));
    expect(view().layout.background, ScoreboardTheme.daylight.background);

    settings.setTheme('neon');
    await tester.pump();
    expect(view().layout.background, ScoreboardTheme.neon.background);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('custom periods apply and restart the match', (tester) async {
    _useLargeWindow(tester);

    final settings = AppSettings();
    await tester.pumpWidget(_app(settings));
    expect(find.text('1st half'), findsWidgets);

    settings.setRule(
      'handball',
      const SportRule(
        periods: 3,
        minutes: 20,
        timeouts: 1,
        timeoutSeconds: 45,
        countUp: false,
      ),
    );
    await tester.pump();
    expect(find.text('20:00'), findsWidgets);
    expect(find.text('Period 1'), findsWidgets);
    expect(find.text('Timeout (1)'), findsNWidgets(2));
    await tester.tap(find.text('Next period'));
    await tester.pump();
    await tester.tap(find.text('Next period'));
    await tester.pump();
    expect(find.text('Period 3'), findsWidgets);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Next period'),
          )
          .onPressed,
      isNull,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('layout follows orientation and fits without scrolling', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    Rect rectOf(Finder finder) => tester.getRect(finder.first);
    final preview = find.byType(ScoreboardView);
    final controls = find.text('Next period');

    tester.view.physicalSize = const Size(1280, 600);
    await tester.pumpWidget(_app(AppSettings()));
    expect(rectOf(controls).right, lessThanOrEqualTo(rectOf(preview).left));
    expect(rectOf(controls).bottom, lessThanOrEqualTo(600));

    tester.view.physicalSize = const Size(600, 1100);
    await tester.pump();
    expect(rectOf(preview).bottom, lessThanOrEqualTo(rectOf(controls).top));
    expect(rectOf(controls).bottom, lessThanOrEqualTo(1100));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('preview can be hidden in the settings', (tester) async {
    _useLargeWindow(tester);

    final settings = AppSettings();
    await tester.pumpWidget(_app(settings));
    expect(find.byType(ScoreboardView), findsOneWidget);

    settings.setShowPreview(false);
    await tester.pump();
    expect(find.byType(ScoreboardView), findsNothing);
    expect(find.text('Next period'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switching to tennis shows set controls and point labels', (
    tester,
  ) async {
    _useLargeWindow(tester);

    await tester.pumpWidget(_app(AppSettings()));
    await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tennis').last);
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(DropdownButton<String>)))
        .popUntil((route) => route.isFirst);
    await tester.pumpAndSettle();
    expect(find.text('Next set'), findsOneWidget);
    expect(find.text('Start (Space)'), findsNothing);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    expect(find.text('15'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });
}
