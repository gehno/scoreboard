import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../l10n/app_language.dart';
import '../storage/app_storage.dart';
import 'shortcuts.dart';
import 'sport_rule.dart';

/// User settings (language, theme, match rules, shortcuts), saved as JSON.
class AppSettings extends ChangeNotifier {
  /// Without [storage] changes are kept in memory only.
  AppSettings({AppStorage? storage}) : _storage = storage ?? MemoryStorage();

  static const _fileName = 'settings.json';

  static Future<AppSettings> load(AppStorage storage) async {
    final settings = AppSettings(storage: storage);
    final json = await storage.read(_fileName);
    if (json != null) {
      try {
        settings._restore(jsonDecode(json) as Map<String, Object?>);
      } catch (_) {
        // Unreadable settings must not block startup; defaults apply.
      }
    }
    return settings;
  }

  final AppStorage _storage;
  final _rules = <String, SportRule>{};
  final _bindings = {
    for (final action in ShortcutAction.values) action: action.defaultBinding,
  };

  AppLanguage _language = AppLanguage.en;
  ScoreboardTheme _theme = ScoreboardTheme.byId(null);

  bool _showPreview = true;

  AppLanguage get language => _language;
  bool get showPreview => _showPreview;
  ScoreboardTheme get theme => _theme;

  void setLanguage(AppLanguage language) {
    _language = language;
    _save();
  }

  void setTheme(String themeId) {
    _theme = ScoreboardTheme.byId(themeId);
    _save();
  }

  void setShowPreview(bool visible) {
    _showPreview = visible;
    _save();
  }

  /// [base] with the user's rules for it applied.
  SportDefinition effectiveSport(SportDefinition base) {
    final rule = _rules[base.id];
    if (rule == null) return base;
    return base.copyWith(
      periods: rule.periods,
      periodDuration: base.hasClock ? Duration(minutes: rule.minutes) : null,
      timeoutsPerMatch: rule.timeouts,
      timeoutDuration: Duration(seconds: rule.timeoutSeconds),
      countUp: base.hasClock ? rule.countUp : null,
    );
  }

  bool hasRule(String sportId) => _rules.containsKey(sportId);

  void setRule(String sportId, SportRule rule) {
    _rules[sportId] = rule.clamped();
    _save();
  }

  void resetRule(String sportId) {
    if (_rules.remove(sportId) != null) _save();
  }

  KeyBinding binding(ShortcutAction action) => _bindings[action]!;

  /// The other action already using [binding], if any.
  ShortcutAction? conflict(ShortcutAction action, KeyBinding binding) {
    for (final entry in _bindings.entries) {
      if (entry.key != action && entry.value == binding) return entry.key;
    }
    return null;
  }

  void setBinding(ShortcutAction action, KeyBinding binding) {
    _bindings[action] = binding;
    _save();
  }

  /// Gives [action] the [binding]; a conflicting action takes over its old one.
  void swapBinding(ShortcutAction action, KeyBinding binding) {
    final other = conflict(action, binding);
    if (other != null) _bindings[other] = this.binding(action);
    setBinding(action, binding);
  }

  void resetShortcuts() {
    for (final action in ShortcutAction.values) {
      _bindings[action] = action.defaultBinding;
    }
    _save();
  }

  void _restore(Map<String, Object?> json) {
    _language = AppLanguage.fromName(json['language'] as String?);
    _theme = ScoreboardTheme.byId(json['theme'] as String?);
    _showPreview = json['showPreview'] as bool? ?? true;

    final rules = (json['rules'] as Map?) ?? const {};
    for (final MapEntry(:key, :value) in rules.entries) {
      final base = SportRegistry.byId(key as String);
      if (base != null && value is Map) {
        _rules[base.id] = SportRule.fromJson(value, base);
      }
    }

    final shortcuts = (json['shortcuts'] as Map?) ?? const {};
    for (final action in ShortcutAction.values) {
      final binding = KeyBinding.tryFromJson(shortcuts[action.name]);
      if (binding != null) _bindings[action] = binding;
    }
  }

  Map<String, Object> _toJson() => {
    'language': _language.name,
    'theme': _theme.id,
    'showPreview': _showPreview,
    'rules': {for (final e in _rules.entries) e.key: e.value.toJson()},
    'shortcuts': {
      for (final e in _bindings.entries) e.key.name: e.value.toJson(),
    },
  };

  void _save() {
    notifyListeners();
    unawaited(_storage.write(_fileName, jsonEncode(_toJson())));
  }
}
