import 'package:scoreboard_core/scoreboard_core.dart';
import 'package:test/test.dart';

void main() {
  test('DisplayMessage survives an encode/decode round trip', () {
    final message = DisplayMessage(defaultHandballLayout(), const {
      'home.score': 3,
      'clock': '12:34',
    });

    final decoded = DisplayMessage.decode(message.encode());

    expect(decoded.values, message.values);
    expect(decoded.layout.encode(), message.layout.encode());
  });

  test('parseClock accepts mm:ss and rejects anything else', () {
    expect(parseClock('12:05'), const Duration(minutes: 12, seconds: 5));
    expect(parseClock(' 7:30 '), const Duration(minutes: 7, seconds: 30));
    expect(parseClock('1205'), isNull);
    expect(parseClock('12:5'), isNull);
    expect(parseClock(''), isNull);
  });

  test('team logo is exposed as binding and bound in default layouts', () {
    final controller = MatchController(MatchState.initial(handball))
      ..setTeamLogo(Side.home, 'C:/logos/home.png');

    final bindings = controller.state.toBindings();
    expect(bindings['home.logo'], 'C:/logos/home.png');
    expect(bindings['away.logo'], '');

    final imagePaths = defaultLayoutFor('handball').elements
        .where((e) => e.type == ElementType.image)
        .map((e) => e.imagePath);
    expect(imagePaths, ['{{home.logo}}', '{{away.logo}}']);
  });
}
