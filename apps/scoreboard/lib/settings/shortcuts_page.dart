import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/localized_values.dart';
import 'settings_page.dart';
import 'settings_scope.dart';
import 'shortcuts.dart';

class ShortcutsPage extends StatelessWidget {
  const ShortcutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    return SettingsSubpage(
      title: context.l10n.keyboardShortcuts,
      actions: [
        TextButton(
          onPressed: settings.resetShortcuts,
          child: Text(context.l10n.resetToDefaults),
        ),
      ],
      children: [
        for (final action in ShortcutAction.values)
          ListTile(
            title: Text(localizedShortcutAction(context.l10n, action)),
            trailing: OutlinedButton(
              onPressed: () => _rebind(context, action),
              child: Text(settings.binding(action).label),
            ),
          ),
      ],
    );
  }

  Future<void> _rebind(BuildContext context, ShortcutAction action) async {
    final settings = context.readSettings;
    final binding = await showDialog<KeyBinding>(
      context: context,
      builder: (_) => _CaptureDialog(action: action),
    );
    if (binding == null || !context.mounted) return;

    final conflicting = settings.conflict(action, binding);
    if (conflicting != null && !await _confirmSwap(context, conflicting)) {
      return;
    }
    settings.swapBinding(action, binding);
  }

  Future<bool> _confirmSwap(BuildContext context, ShortcutAction other) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          context.l10n.alreadyUsedByActionTheTwoKeysWillBeSwapped(
            localizedShortcutAction(context.l10n, other),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.useHere),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

/// Waits for the next key press and returns it as the new binding.
class _CaptureDialog extends StatelessWidget {
  const _CaptureDialog({required this.action});

  final ShortcutAction action;

  static final _modifierKeys = {
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  };

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent && !_modifierKeys.contains(event.logicalKey)) {
        Navigator.pop(
          context,
          KeyBinding(
            event.logicalKey,
            ctrl: HardwareKeyboard.instance.isControlPressed,
          ),
        );
      }
      return KeyEventResult.handled;
    },
    child: AlertDialog(
      title: Text(localizedShortcutAction(context.l10n, action)),
      content: Text(context.l10n.pressTheNewKeyCombination),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ],
    ),
  );
}
