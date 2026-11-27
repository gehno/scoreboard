import 'package:flutter_test/flutter_test.dart';
import 'package:scoreboard_app/storage/backup_service.dart';

void main() {
  test('backup round-trips files', () {
    final files = {'settings.json': '{"theme":"dark"}', 'football.json': '{}'};
    expect(BackupService.decode(BackupService.encode(files)), files);
  });

  test('backup rejects non-zip and unexpected content', () {
    expect(() => BackupService.decode([1, 2, 3]), throwsFormatException);
    expect(
      () => BackupService.decode(BackupService.encode({'../evil.json': '{}'})),
      throwsFormatException,
    );
    expect(
      () => BackupService.decode(BackupService.encode({'notes.txt': 'x'})),
      throwsFormatException,
    );
  });
}
