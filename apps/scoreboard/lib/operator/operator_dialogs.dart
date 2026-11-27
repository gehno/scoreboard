import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../settings/settings_scope.dart';

/// Asks for a jersey number. Returns '' if left empty, null if cancelled.
Future<String?> askJerseyNumber(BuildContext context) => showDialog<String>(
  context: context,
  builder: (context) => _TextPrompt(
    title: context.l10n.jerseyNumber,
    hint: context.l10n.optional,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
  ),
);

/// Asks for a new clock value; null if cancelled or not a valid `mm:ss`.
Future<Duration?> askClock(BuildContext context, Duration current) async {
  final text = await showDialog<String>(
    context: context,
    builder: (context) => _TextPrompt(
      title: context.l10n.setClockMmSs,
      initialText: formatClock(current),
    ),
  );
  return text == null ? null : parseClock(text);
}

/// Asks on which of [count] monitors (0-based) to show the display.
Future<int?> pickMonitor(BuildContext context, int count) => showDialog<int>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(context.l10n.showScoreboardOnWhichMonitor),
    children: [
      for (var i = 0; i < count; i++)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, i),
          child: Text(context.l10n.monitorN(i + 1)),
        ),
    ],
  ),
);

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    this.initialText = '',
    this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final String title;
  final String initialText;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String text) => Navigator.pop(context, text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: _submit,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => _submit(_controller.text),
        child: Text(context.l10n.ok),
      ),
    ],
  );
}
