import 'package:scoreboard_core/scoreboard_core.dart';

import 'app_storage.dart';

/// Saves one layout per sport and falls back to the default layout when
/// nothing usable is stored.
class LayoutRepository {
  const LayoutRepository(this._storage);

  final AppStorage _storage;

  Future<ScoreboardLayout> load(String sportId) async {
    final json = await _storage.read(_fileName(sportId));
    if (json != null) {
      try {
        return ScoreboardLayout.decode(json);
      } catch (_) {
        // A corrupt file must not block the app; the default layout replaces it.
      }
    }
    return defaultLayoutFor(sportId);
  }

  Future<void> save(ScoreboardLayout layout) =>
      _storage.write(_fileName(layout.sportId), layout.encode());

  String _fileName(String sportId) => '$sportId.json';
}
