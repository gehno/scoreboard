/// Persistence the app needs, kept free of `dart:io` so it is easy to fake.
abstract interface class AppStorage {
  /// Contents of [name], or null if it does not exist.
  Future<String?> read(String name);

  Future<void> write(String name, String content);

  /// Every stored file by name.
  Future<Map<String, String>> readAll();
}

class MemoryStorage implements AppStorage {
  final _files = <String, String>{};

  @override
  Future<String?> read(String name) async => _files[name];

  @override
  Future<void> write(String name, String content) async =>
      _files[name] = content;

  @override
  Future<Map<String, String>> readAll() async => Map.of(_files);
}
