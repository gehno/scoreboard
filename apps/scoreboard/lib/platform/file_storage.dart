import 'dart:io';

import '../storage/app_storage.dart';

/// [AppStorage] backed by a per-user configuration directory.
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

  static Directory _baseDirectory() {
    if (Platform.isWindows) {
      return Directory(
        Platform.environment['APPDATA'] ?? Directory.systemTemp.path,
      );
    }
    if (Platform.isLinux) {
      final configHome = Platform.environment['XDG_CONFIG_HOME'];
      if (configHome != null &&
          configHome.isNotEmpty &&
          Directory(configHome).isAbsolute) {
        return Directory(configHome);
      }
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory('$home${Platform.pathSeparator}.config');
      }
    }
    return Directory.systemTemp;
  }

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
