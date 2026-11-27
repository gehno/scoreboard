import 'package:material_ui/material_ui.dart';

/// Alignment grid drawn over the virtual canvas; every fifth line is emphasised.
class GridPainter extends CustomPainter {
  const GridPainter(this.spacing);

  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;
    final thick = Paint()
      ..color = Colors.white54
      ..strokeWidth = 3;
    var index = 0;
    for (var x = 0.0; x <= size.width; x += spacing, index++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        index % 5 == 0 ? thick : thin,
      );
    }
    index = 0;
    for (var y = 0.0; y <= size.height; y += spacing, index++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        index % 5 == 0 ? thick : thin,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter old) => old.spacing != spacing;
}

/// Lines through the coordinates the dragged element is currently aligned to.
class GuidePainter extends CustomPainter {
  const GuidePainter({required this.xs, required this.ys});

  final List<double> xs;
  final List<double> ys;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 3;
    for (final x in xs) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (final y in ys) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GuidePainter old) => old.xs != xs || old.ys != ys;
}
