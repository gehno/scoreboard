import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard_app/settings/image_source.dart';

void main() {
  test('recognises supported image types case-insensitively', () {
    expect(isSupportedImage(r'C:\logos\Team.PNG'), isTrue);
    expect(isSupportedImage('crest.svg'), isTrue);
    expect(isSupportedImage('notes.txt'), isFalse);
    expect(isSupportedImage('noextension'), isFalse);
  });
}
