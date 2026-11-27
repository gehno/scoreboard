import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_app/editor/editor_page.dart';
import 'package:scoreboard_app/l10n/app_localizations.dart';
import 'package:scoreboard_app/scoreboard/scoreboard_view.dart';
import 'package:scoreboard_app/settings/app_settings.dart';
import 'package:scoreboard_app/settings/settings_scope.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

LayoutElement _rect(String id, double x, double y) => LayoutElement(
  id: id,
  type: ElementType.rect,
  x: x,
  y: y,
  width: 200,
  height: 100,
);

/// Drags element `a` by [dragBy] virtual units in the editor and returns the
/// saved layout.
Future<ScoreboardLayout> _dragA(
  WidgetTester tester,
  List<LayoutElement> elements,
  Offset dragBy,
) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final layout = defaultLayoutFor('football').copyWith(elements: elements);
  ScoreboardLayout? saved;
  await tester.pumpWidget(
    SettingsScope(
      settings: AppSettings(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => saved = await Navigator.push(
              context,
              MaterialPageRoute<ScoreboardLayout>(
                builder: (_) => EditorPage(layout: layout, values: const {}),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  final view = tester.getRect(find.byType(ScoreboardView));
  final scale = [
    view.width / layout.width,
    view.height / layout.height,
  ].reduce((a, b) => a < b ? a : b);
  final canvasOrigin =
      view.center - Offset(layout.width, layout.height) * scale / 2;
  final a = elements.first;
  final start = canvasOrigin + Offset(a.x + 100, a.y + 50) * scale;
  final gesture = await tester.startGesture(start);
  await gesture.moveBy(const Offset(30, 0));
  await gesture.moveBy(dragBy * scale);
  await gesture.up();
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.save));
  await tester.pumpAndSettle();
  return saved!;
}

void main() {
  testWidgets('dragging snaps to the grid', (tester) async {
    final saved = await _dragA(tester, [
      _rect('a', 105, 107),
    ], const Offset(47, 23));
    expect(saved.elements.single.x % 20, 0);
    expect(saved.elements.single.y % 20, 0);
  });

  testWidgets('dragging aligns with the edge of another element', (
    tester,
  ) async {
    final saved = await _dragA(tester, [
      _rect('a', 100, 100),
      _rect('b', 603, 700),
    ], const Offset(500, 0));
    expect(saved.elements.first.x, 603);
  });
}
