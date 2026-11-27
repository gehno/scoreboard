import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard_app/app/about.dart';

void main() {
  test('reads version and author from pubspec text', () {
    final info = AppInfo.parse('''
name: scoreboard_app
version: 1.2.3+4
app_author: Jane Doe
''');
    expect(info.version, '1.2.3');
    expect(info.author, 'Jane Doe');
  });

  test('bundled pubspec provides real values', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final info = await AppInfo.load();
    expect(info.version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    expect(info.author, isNotEmpty);
  });
}
