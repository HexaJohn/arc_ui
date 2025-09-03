import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  GridPainter({
    this.backgroundColor = Colors.white,
    this.gridColor = Colors.black,
    this.gridSize = 20.0,
    this.gridStroke = 1.0,
  });

  Color backgroundColor;
  Color gridColor;
  double gridSize;
  double gridStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = gridColor
          ..strokeWidth = gridStroke;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
