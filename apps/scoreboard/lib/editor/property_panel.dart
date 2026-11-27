import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../settings/settings_scope.dart';

/// Edits the numeric, text and colour properties of one layout element.
class PropertyPanel extends StatelessWidget {
  const PropertyPanel({
    super.key,
    required this.element,
    required this.onChanged,
  });

  final LayoutElement element;
  final ValueChanged<LayoutElement> onChanged;

  @override
  Widget build(BuildContext context) {
    final e = element;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(e.id, style: Theme.of(context).textTheme.labelSmall),
        if (e.type == ElementType.text)
          _textField(
            'text',
            context.l10n.text,
            e.text,
            (v) => onChanged(e.copyWith(text: v)),
            helper: context.l10n.useHomeScoreClock,
          ),
        if (e.type == ElementType.image)
          _textField(
            'image',
            context.l10n.imageFilePath,
            e.imagePath ?? '',
            (v) => onChanged(e.copyWith(imagePath: v)),
          ),
        _textField(
          'visible',
          context.l10n.visibleWhen,
          e.visibleWhen ?? '',
          (v) => onChanged(e.copyWith(visibleWhen: v)),
          helper: context.l10n.eGTimeoutActiveOrTimeoutActive,
        ),
        _numberField(
          'x',
          context.l10n.x,
          e.x,
          (v) => onChanged(e.copyWith(x: v)),
        ),
        _numberField(
          'y',
          context.l10n.y,
          e.y,
          (v) => onChanged(e.copyWith(y: v)),
        ),
        _numberField(
          'width',
          context.l10n.width,
          e.width,
          (v) => onChanged(e.copyWith(width: v)),
        ),
        _numberField(
          'height',
          context.l10n.height,
          e.height,
          (v) => onChanged(e.copyWith(height: v)),
        ),
        if (e.type == ElementType.text) ...[
          _numberField(
            'fontSize',
            context.l10n.fontSize,
            e.fontSize,
            (v) => onChanged(e.copyWith(fontSize: v)),
          ),
          SwitchListTile(
            title: Text(context.l10n.bold),
            value: e.bold,
            onChanged: (v) => onChanged(e.copyWith(bold: v)),
          ),
          Text(context.l10n.textColor),
          _Palette(
            selected: e.color,
            onPick: (c) => onChanged(e.copyWith(color: c)),
          ),
        ],
        _numberField(
          'radius',
          context.l10n.cornerRadius,
          e.cornerRadius,
          (v) => onChanged(e.copyWith(cornerRadius: v)),
        ),
        Text(context.l10n.background),
        _Palette(
          selected: e.background,
          onPick: (c) => onChanged(e.copyWith(background: c)),
        ),
      ],
    );
  }

  // Keys include the element id so fields reset when the selection changes.
  Widget _textField(
    String name,
    String label,
    String value,
    ValueChanged<String> onChange, {
    String? helper,
  }) => TextFormField(
    key: ValueKey('$name${element.id}'),
    initialValue: value,
    decoration: InputDecoration(labelText: label, helperText: helper),
    onChanged: onChange,
  );

  Widget _numberField(
    String name,
    String label,
    double value,
    ValueChanged<double> onChange,
  ) => TextFormField(
    key: ValueKey('$name${element.id}${value.round()}'),
    initialValue: value.round().toString(),
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    onChanged: (text) {
      final number = double.tryParse(text);
      if (number != null) onChange(number);
    },
  );
}

class _Palette extends StatelessWidget {
  const _Palette({required this.selected, required this.onPick});

  final int selected;
  final ValueChanged<int> onPick;

  static const _colors = [
    0x00000000,
    0xFFFFFFFF,
    0xFF000000,
    0xFFFFD400,
    0xFFFF6B6B,
    0xFF2E86FF,
    0xFF2ECC71,
    0xFF0B1B2B,
    0x33FFFFFF,
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final color in _colors)
        InkWell(
          onTap: () => onPick(color),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Color(color),
              border: Border.all(
                color: color == selected ? Colors.cyanAccent : Colors.grey,
                width: color == selected ? 3 : 1,
              ),
            ),
            child: color == 0 ? const Icon(Icons.block, size: 16) : null,
          ),
        ),
    ],
  );
}
