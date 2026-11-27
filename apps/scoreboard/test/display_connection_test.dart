import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard_app/platform/display_connection.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

void main() {
  test('display stream ends when the operator goes away', () async {
    final server = await DisplayServer.start();
    final layout = defaultLayoutFor('football');
    server.show(DisplayMessage(layout, const {}));

    final messages = connectToOperator(server.port);
    final done = messages.toList();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await server.close();

    expect(await done.timeout(const Duration(seconds: 5)), hasLength(1));
  });
}
