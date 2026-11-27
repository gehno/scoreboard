import 'dart:convert';

import 'package:archive/archive.dart';

import 'app_storage.dart';

/// Where backup archives are chosen and read or written.
abstract interface class BackupFiles {
  bool get isAvailable;

  /// Asks where to save the backup; null if cancelled.
  Future<String?> chooseExportPath(String suggestedName);

  /// Asks which backup to restore; null if cancelled.
  Future<String?> chooseImportPath();

  Future<void> write(String path, List<int> bytes);

  Future<List<int>> read(String path);
}

class NoBackupFiles implements BackupFiles {
  const NoBackupFiles();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> chooseExportPath(String suggestedName) async => null;

  @override
  Future<String?> chooseImportPath() async => null;

  @override
  Future<void> write(String path, List<int> bytes) async {}

  @override
  Future<List<int>> read(String path) async => const [];
}

/// Exports all persisted data (settings and layouts) as one zip archive and
/// restores it again.
class BackupService {
  const BackupService(this._storage, this._files);

  final AppStorage _storage;
  final BackupFiles _files;

  bool get isAvailable => _files.isAvailable;

  /// Path of the written archive, or null if the user cancelled.
  Future<String?> export() async {
    final path = await _files.chooseExportPath(_suggestedName());
    if (path == null) return null;
    await _files.write(path, encode(await _storage.readAll()));
    return path;
  }

  /// Number of restored files, or null if the user cancelled. Throws a
  /// [FormatException] if the chosen file is not a valid backup.
  Future<int?> import() async {
    final path = await _files.chooseImportPath();
    if (path == null) return null;
    final restored = decode(await _files.read(path));
    for (final entry in restored.entries) {
      await _storage.write(entry.key, entry.value);
    }
    return restored.length;
  }

  static List<int> encode(Map<String, String> files) {
    final archive = Archive();
    for (final entry in files.entries) {
      archive.add(ArchiveFile.bytes(entry.key, utf8.encode(entry.value)));
    }
    return ZipEncoder().encode(archive);
  }

  /// Only flat `.json` files are accepted so a backup cannot write elsewhere.
  static Map<String, String> decode(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('Not a zip archive');
    }
    final files = <String, String>{};
    for (final file in archive.files.where((f) => f.isFile)) {
      final name = file.name;
      if (!name.endsWith('.json') ||
          name.contains('/') ||
          name.contains(r'\')) {
        throw FormatException('Unexpected file in backup: $name');
      }
      final content = utf8.decode(file.readBytes() ?? const []);
      jsonDecode(content);
      files[name] = content;
    }
    if (files.isEmpty) throw const FormatException('Backup is empty');
    return files;
  }

  String _suggestedName() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'scoreboard-backup-${now.year}${two(now.month)}${two(now.day)}.zip';
  }
}
