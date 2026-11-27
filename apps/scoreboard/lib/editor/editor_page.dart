import 'package:material_ui/material_ui.dart';
import 'package:scoreboard_core/scoreboard_core.dart';

import '../scoreboard/scoreboard_view.dart';
import '../settings/settings_scope.dart';
import 'grid_painter.dart';
import 'property_panel.dart';

/// Drag-and-drop layout editor with live preview. Pops the edited layout
/// when the user saves.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.layout, required this.values});

  final ScoreboardLayout layout;
  final Map<String, Object> values;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  static const _alignTolerance = 8.0;
  static const _exactTolerance = 0.5;
  static const _gridSizes = [5.0, 10.0, 20.0, 40.0, 50.0, 100.0];

  late ScoreboardLayout _layout = widget.layout;
  final _history = <ScoreboardLayout>[];
  String? _selectedId;
  bool _showGrid = false;
  bool _snapToGrid = true;
  double _gridSpacing = 20;
  Offset? _dragPosition;
  List<double> _guideXs = const [];
  List<double> _guideYs = const [];

  LayoutElement? get _selected {
    for (final element in _layout.elements) {
      if (element.id == _selectedId) return element;
    }
    return null;
  }

  /// Property edits and drags are continuous, so they are not recorded
  /// individually in the undo history.
  void _updateElement(LayoutElement updated) => setState(() {
    _layout = _layout.copyWith(
      elements: [
        for (final e in _layout.elements) e.id == updated.id ? updated : e,
      ],
    );
  });

  void _changeStructure(List<LayoutElement> elements, {String? select}) =>
      setState(() {
        _history.add(_layout);
        _layout = _layout.copyWith(elements: elements);
        _selectedId = select;
      });

  void _add(ElementType type) {
    final id = '${type.name}_${DateTime.now().microsecondsSinceEpoch}';
    _changeStructure([
      ..._layout.elements,
      LayoutElement(
        id: id,
        type: type,
        x: 100,
        y: 100,
        width: 400,
        height: 160,
        text: type == ElementType.text ? 'Text {{clock}}' : '',
        background: type == ElementType.rect ? 0xFF334455 : 0,
      ),
    ], select: id);
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    _changeStructure(
      _layout.elements.where((e) => e.id != _selectedId).toList(),
    );
  }

  void _moveSelected({required bool forward}) {
    final from = _layout.elements.indexWhere((e) => e.id == _selectedId);
    final to = forward ? from + 1 : from - 1;
    if (from < 0 || to < 0 || to >= _layout.elements.length) return;
    final elements = [..._layout.elements];
    elements.insert(to, elements.removeAt(from));
    _changeStructure(elements, select: _selectedId);
  }

  /// Keeps the unsnapped position while dragging so small movements are not
  /// swallowed by snapping. Edges and centres of other elements and of the
  /// canvas take precedence over the grid.
  void _drag(String id, Offset delta) {
    _selectedId = id;
    final element = _layout.elements.firstWhere((e) => e.id == id);
    final raw = (_dragPosition ?? Offset(element.x, element.y)) + delta;
    _dragPosition = raw;

    final others = _layout.elements.where((e) => e.id != id).toList();
    final xTargets = _targets(_layout.width, others.map((e) => (e.x, e.width)));
    final yTargets = _targets(
      _layout.height,
      others.map((e) => (e.y, e.height)),
    );
    final tolerance = _snapToGrid ? _alignTolerance : _exactTolerance;
    final x = _alignAxis(raw.dx, element.width, xTargets, tolerance);
    final y = _alignAxis(raw.dy, element.height, yTargets, tolerance);
    final grid = _snap(raw);
    final position = Offset(x ?? grid.dx, y ?? grid.dy);

    _guideXs = _matches(position.dx, element.width, xTargets);
    _guideYs = _matches(position.dy, element.height, yTargets);
    _updateElement(element.copyWith(x: position.dx, y: position.dy));
  }

  Offset _snap(Offset position) {
    if (!_snapToGrid) return position;
    double snap(double value) =>
        (value / _gridSpacing).roundToDouble() * _gridSpacing;
    return Offset(snap(position.dx), snap(position.dy));
  }

  void _endDrag() => setState(() {
    _dragPosition = null;
    _guideXs = const [];
    _guideYs = const [];
  });

  /// Start, centre and end of the canvas and of every other element.
  List<double> _targets(double canvasSize, Iterable<(double, double)> others) =>
      [
        for (final (start, size) in [(0.0, canvasSize), ...others]) ...[
          start,
          start + size / 2,
          start + size,
        ],
      ];

  static List<double> _anchors(double start, double size) => [
    start,
    start + size / 2,
    start + size,
  ];

  /// New start coordinate that aligns an anchor with the nearest target, or
  /// null if none is within [tolerance].
  double? _alignAxis(
    double start,
    double size,
    List<double> targets,
    double tolerance,
  ) {
    double? best;
    var bestDistance = tolerance;
    for (final anchor in _anchors(start, size)) {
      for (final target in targets) {
        final distance = (target - anchor).abs();
        if (distance <= bestDistance) {
          bestDistance = distance;
          best = start + target - anchor;
        }
      }
    }
    return best;
  }

  List<double> _matches(double start, double size, List<double> targets) => {
    for (final anchor in _anchors(start, size))
      for (final target in targets)
        if ((target - anchor).abs() < _exactTolerance) target,
  }.toList();
  void _undo() => setState(() => _layout = _history.removeLast());

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.layoutEditorName(_layout.name)),
        actions: [
          _action(
            context.l10n.addText,
            Icons.text_fields,
            () => _add(ElementType.text),
          ),
          _action(
            context.l10n.addRectangle,
            Icons.crop_square,
            () => _add(ElementType.rect),
          ),
          _action(
            context.l10n.addImage,
            Icons.image,
            () => _add(ElementType.image),
          ),
          _action(
            context.l10n.bringForward,
            Icons.flip_to_front,
            () => _moveSelected(forward: true),
          ),
          _action(
            context.l10n.sendBackward,
            Icons.flip_to_back,
            () => _moveSelected(forward: false),
          ),
          _action(context.l10n.delete, Icons.delete, _deleteSelected),
          _action(
            _showGrid ? context.l10n.hideGrid : context.l10n.showGrid,
            Icons.grid_4x4,
            () => setState(() => _showGrid = !_showGrid),
            active: _showGrid,
          ),
          _action(
            _snapToGrid
                ? context.l10n.snapToGridOn
                : context.l10n.snapToGridOff,
            Icons.straighten,
            () => setState(() => _snapToGrid = !_snapToGrid),
            active: _snapToGrid,
          ),
          PopupMenuButton<double>(
            tooltip: context.l10n.gridSize,
            icon: const Icon(Icons.format_line_spacing),
            initialValue: _gridSpacing,
            onSelected: (value) => setState(() => _gridSpacing = value),
            itemBuilder: (_) => [
              for (final size in _gridSizes)
                PopupMenuItem(value: size, child: Text('${size.round()}')),
            ],
          ),
          _action(
            context.l10n.undo,
            Icons.undo,
            _history.isEmpty ? null : _undo,
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _layout),
            icon: const Icon(Icons.save),
            label: Text(context.l10n.save),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(child: _canvas()),
          SizedBox(
            width: 300,
            child: selected == null
                ? Center(child: Text(context.l10n.selectAnElement))
                : PropertyPanel(element: selected, onChanged: _updateElement),
          ),
        ],
      ),
    );
  }

  Widget _action(
    String tooltip,
    IconData icon,
    VoidCallback? onPressed, {
    bool active = false,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    isSelected: active,
    icon: Icon(icon),
  );

  Widget _canvas() => ScoreboardView(
    layout: _layout,
    values: widget.values,
    selectedId: _selectedId,
    onElementTap: (id) => setState(() => _selectedId = id),
    onElementDrag: _drag,
    onElementDragEnd: _endDrag,
    overlay: Stack(
      fit: StackFit.expand,
      children: [
        if (_showGrid) CustomPaint(painter: GridPainter(_gridSpacing)),
        CustomPaint(
          painter: GuidePainter(xs: _guideXs, ys: _guideYs),
        ),
      ],
    ),
  );
}
