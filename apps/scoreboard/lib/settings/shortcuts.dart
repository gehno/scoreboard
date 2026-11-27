import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

enum ShortcutAction {
  toggleClock('Start/stop clock', LogicalKeyboardKey.space),
  homePlus('Home +1', LogicalKeyboardKey.keyQ),
  homeMinus('Home −1', LogicalKeyboardKey.keyA),
  awayPlus('Away +1', LogicalKeyboardKey.keyP),
  awayMinus('Away −1', LogicalKeyboardKey.keyL),
  homeTimeout('Home timeout', LogicalKeyboardKey.keyW),
  awayTimeout('Away timeout', LogicalKeyboardKey.keyO),
  homeSuspension('Home suspension', LogicalKeyboardKey.keyE),
  awaySuspension('Away suspension', LogicalKeyboardKey.keyI),
  nextPeriod('Next period / set', LogicalKeyboardKey.keyN),
  cancelTimeout('Abort timeout', LogicalKeyboardKey.escape),
  undo('Undo', LogicalKeyboardKey.keyZ, ctrl: true),
  redo('Redo', LogicalKeyboardKey.keyY, ctrl: true);

  const ShortcutAction(this.label, this.defaultKey, {this.ctrl = false});

  /// English UI text; translate before showing.
  final String label;
  final LogicalKeyboardKey defaultKey;
  final bool ctrl;

  KeyBinding get defaultBinding => KeyBinding(defaultKey, ctrl: ctrl);
}

@immutable
class KeyBinding {
  const KeyBinding(this.key, {this.ctrl = false});

  /// Null if the stored key no longer exists.
  static KeyBinding? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final keyId = json['key'];
    final key = keyId is int ? LogicalKeyboardKey.findKeyByKeyId(keyId) : null;
    return key == null ? null : KeyBinding(key, ctrl: json['ctrl'] == true);
  }

  final LogicalKeyboardKey key;
  final bool ctrl;

  SingleActivator get activator => SingleActivator(key, control: ctrl);

  String get label {
    final name = key == LogicalKeyboardKey.space
        ? 'Space'
        : (key.keyLabel.isNotEmpty ? key.keyLabel : key.debugName ?? '?');
    return ctrl ? 'Ctrl+$name' : name;
  }

  Map<String, Object> toJson() => {'key': key.keyId, 'ctrl': ctrl};

  @override
  bool operator ==(Object other) =>
      other is KeyBinding && other.key == key && other.ctrl == ctrl;

  @override
  int get hashCode => Object.hash(key, ctrl);
}
