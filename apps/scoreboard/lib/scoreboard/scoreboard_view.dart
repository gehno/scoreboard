import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../platform/local_image.dart';

/// Renders a layout against binding values on a fixed virtual canvas, scaled
/// to fit. The display, the operator preview and the layout editor all use it
/// so they look identical.
class ScoreboardView extends StatelessWidget {
  const ScoreboardView({
    super.key,
    required this.layout,
    required this.values,
    this.selectedId,
    this.onElementTap,
    this.onElementDrag,
    this.onElementDragEnd,
    this.overlay,
  });

  final ScoreboardLayout layout;
  final Map<String, Object> values;
  final String? selectedId;
  final ValueChanged<String>? onElementTap;

  /// The delta is in virtual canvas units.
  final void Function(String id, Offset delta)? onElementDrag;

  final VoidCallback? onElementDragEnd;

  /// Drawn above all elements in virtual canvas units; ignores pointer input.
  final Widget? overlay;

  bool get _isEditing => onElementTap != null;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: FittedBox(
      child: SizedBox(
        width: layout.width,
        height: layout.height,
        child: ClipRect(
          child: ColoredBox(
            color: Color(layout.background),
            child: Stack(
              children: [
                for (final element in layout.elements)
                  if (_isEditing || isVisible(element.visibleWhen, values))
                    _positioned(element),
                if (overlay != null)
                  Positioned.fill(child: IgnorePointer(child: overlay)),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _positioned(LayoutElement element) {
    final visible = isVisible(element.visibleWhen, values);
    return Positioned(
      left: element.x,
      top: element.y,
      width: element.width,
      height: element.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onElementTap == null ? null : () => onElementTap!(element.id),
        onPanUpdate: onElementDrag == null
            ? null
            : (details) => onElementDrag!(element.id, details.delta),
        onPanEnd: (_) => onElementDragEnd?.call(),
        onPanCancel: () => onElementDragEnd?.call(),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: element.id == selectedId
                ? Border.all(color: Colors.cyanAccent, width: 4)
                : null,
          ),
          child: Opacity(opacity: visible ? 1 : 0.3, child: _content(element)),
        ),
      ),
    );
  }

  Widget _content(LayoutElement element) {
    final box = BoxDecoration(
      color: Color(element.background),
      borderRadius: BorderRadius.circular(element.cornerRadius),
    );
    return switch (element.type) {
      ElementType.rect => DecoratedBox(decoration: box),
      ElementType.image => DecoratedBox(
        decoration: box,
        child: _image(element),
      ),
      ElementType.text => DecoratedBox(
        decoration: box,
        child: Align(
          alignment: switch (element.align) {
            'left' => Alignment.centerLeft,
            'right' => Alignment.centerRight,
            _ => Alignment.center,
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              resolveBindings(element.text, values),
              style: TextStyle(
                color: Color(element.color),
                fontSize: element.fontSize,
                fontFamily: element.fontFamily,
                fontWeight: element.bold ? FontWeight.bold : FontWeight.normal,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    };
  }

  Widget _image(LayoutElement element) {
    final path = resolveBindings(element.imagePath ?? '', values);
    return path.isEmpty ? const SizedBox.shrink() : LocalImage(path);
  }
}
