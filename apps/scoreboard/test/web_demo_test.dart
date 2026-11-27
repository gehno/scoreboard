import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_app/platform/startup_web.dart' as web;
import 'package:scoreboard_app/scoreboard/scoreboard_view.dart';

void main() {
  testWidgets('web demo starts with a working scoreboard preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await web.start([]);
    await tester.pumpAndSettle();
    expect(find.byType(ScoreboardView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    expect(find.text('1'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });
}
