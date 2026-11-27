import 'dart:io';

import '../storage/backup_service.dart';
import 'window_control.dart';

/// [BackupFiles] using native desktop file dialogs.
class WindowBackupFiles implements BackupFiles {
  const WindowBackupFiles();

  @override
  bool get isAvailable => true;

  @override
  Future<String?> chooseExportPath(String suggestedName) =>
      WindowControl.chooseFile(
        save: true,
        filterName: 'Zip archive',
        pattern: '*.zip',
        defaultName: suggestedName,
      );

  @override
  Future<String?> chooseImportPath() => WindowControl.chooseFile(
    save: false,
    filterName: 'Zip archive',
    pattern: '*.zip',
  );

  @override
  Future<void> write(String path, List<int> bytes) =>
      File(path).writeAsBytes(bytes);

  @override
  Future<List<int>> read(String path) => File(path).readAsBytes();
}

BackupFiles createBackupFiles() => WindowControl.isSupported
    ? const WindowBackupFiles()
    : const NoBackupFiles();
