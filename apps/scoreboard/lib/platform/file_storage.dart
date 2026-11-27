import 'dart:io';

import '../storage/app_storage.dart';

/// [AppStorage] backed by a per-user data directory. Uses no plugin, so
/// Windows builds need no symlink/Developer Mode support.
class FileStorage implements AppStorage {
  FileStorage._(this._directory);

  final Directory _directory;

  static Future<FileStorage> open() async {
    final base = _baseDirectory().path;
    final directory = Directory(
      '$base${Platform.pathSeparator}scoreboard_layouts',
    );
    await directory.create(recursive: true);
    return FileStorage._(directory);
  }

  /// The per-user application data directory (`%APPDATA%`).
  static Directory _baseDirectory() =>
      Directory(Platform.environment['APPDATA'] ?? Directory.systemTemp.path);

  File _file(String name) =>
      File('${_directory.path}${Platform.pathSeparator}$name');

  @override
  Future<String?> read(String name) async {
    final file = _file(name);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String name, String content) =>
      _file(name).writeAsString(content);

  @override
  Future<Map<String, String>> readAll() async {
    final files = <String, String>{};
    await for (final entity in _directory.list()) {
      if (entity is File) {
        files[entity.uri.pathSegments.last] = await entity.readAsString();
      }
    }
    return files;
  }
}
