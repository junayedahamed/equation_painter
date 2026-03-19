import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'equation_config.dart';

class GraphPainter extends CustomPainter {
  final List<Float32List> allPoints;
  final List<EquationConfig> equations;
  final double animationProgress;

  GraphPainter({
    required this.allPoints,
    required this.equations,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (allPoints.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < allPoints.length; i++) {
      if (i >= equations.length) break;
      final points = allPoints[i];
      final config = equations[i];
      paint.color = config.color;
      paint.strokeWidth = config.strokeWidth;

      final totalSegments = points.length ~/ 4;
      final countToDraw = (totalSegments * animationProgress).toInt();
      if (countToDraw <= 0) continue;

      final pointsToDraw = Float32List.sublistView(points, 0, countToDraw * 4);
      canvas.drawRawPoints(ui.PointMode.lines, pointsToDraw, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.allPoints != allPoints ||
        oldDelegate.equations != equations;
  }
}
