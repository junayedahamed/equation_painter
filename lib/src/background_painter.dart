import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  final bool showGrid;
  final bool showAxis;
  final Color gridColor;
  final double gridStrokeWidth;
  final Alignment alignment;
  final bool showNumbers;
  final double unitsPerSquare;
  final Color labelColor;
  final Color xAxisColor;
  final Color yAxisColor;

  BackgroundPainter({
    required this.showGrid,
    required this.showAxis,
    required this.gridColor,
    required this.gridStrokeWidth,
    required this.alignment,
    required this.showNumbers,
    required this.unitsPerSquare,
    required this.labelColor,
    required this.xAxisColor,
    required this.yAxisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint();

    final originX = (1 + alignment.x) * w / 2;
    final originY = (1 + alignment.y) * h / 2;

    const double gridStep = 40.0;

    if (showGrid) {
      paint.color = gridColor;
      paint.strokeWidth = gridStrokeWidth;

      for (double x = originX; x <= w; x += gridStep) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      }
      for (double x = originX - gridStep; x >= 0; x -= gridStep) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      }

      for (double y = originY; y <= h; y += gridStep) {
        canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      }
      for (double y = originY - gridStep; y >= 0; y -= gridStep) {
        canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      }
    }

    if (showAxis) {
      paint.strokeWidth = 2.0;

      if (originY >= 0 && originY <= h) {
        paint.color = xAxisColor;
        canvas.drawLine(Offset(0, originY), Offset(w, originY), paint);
      }
      if (originX >= 0 && originX <= w) {
        paint.color = yAxisColor;
        canvas.drawLine(Offset(originX, 0), Offset(originX, h), paint);
      }

      if (showNumbers) {
        _drawLabels(canvas, size, originX, originY);
      }
    }
  }

  void _drawLabels(Canvas canvas, Size size, double originX, double originY) {
    final w = size.width;
    final h = size.height;

    const double gridStep = 40.0;

    final textStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    void drawText(String text, Offset pos, {bool isX = true}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      double dx = pos.dx;
      double dy = pos.dy;

      if (isX) {
        dx -= tp.width / 2;
        dy += 4;
        if (dy + tp.height > h) dy -= (tp.height + 8);
      } else {
        dx += 4;
        dy -= tp.height / 2;
        if (dx + tp.width > w) dx -= (tp.width + 8);
      }

      tp.paint(canvas, Offset(dx, dy));
    }

    int xCount = 1;
    for (double x = originX + gridStep; x <= w; x += gridStep) {
      final val = xCount * unitsPerSquare;
      drawText(_format(val), Offset(x, originY), isX: true);
      xCount++;
    }
    xCount = -1;
    for (double x = originX - gridStep; x >= 0; x -= gridStep) {
      final val = xCount * unitsPerSquare;
      drawText(_format(val), Offset(x, originY), isX: true);
      xCount--;
    }

    int yCount = 1;
    for (double y = originY - gridStep; y >= 0; y -= gridStep) {
      final val = yCount * unitsPerSquare;
      drawText(_format(val), Offset(originX, y), isX: false);
      yCount++;
    }
    yCount = -1;
    for (double y = originY + gridStep; y <= h; y += gridStep) {
      final val = yCount * unitsPerSquare;
      drawText(_format(val), Offset(originX, y), isX: false);
      yCount--;
    }
  }

  String _format(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    
    // Automatically adjust decimal places based on zoom magnitude
    if (v.abs() < 0.01) return v.toStringAsExponential(1);
    if (v.abs() < 0.1) return v.toStringAsFixed(3);
    if (v.abs() < 1) return v.toStringAsFixed(2);
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.showGrid != showGrid ||
        oldDelegate.showAxis != showAxis ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.gridStrokeWidth != gridStrokeWidth ||
        oldDelegate.alignment != alignment ||
        oldDelegate.showNumbers != showNumbers ||
        oldDelegate.unitsPerSquare != unitsPerSquare ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.xAxisColor != xAxisColor ||
        oldDelegate.yAxisColor != yAxisColor;
  }
}
