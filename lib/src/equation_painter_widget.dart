import 'package:flutter/material.dart';

typedef MathFunction = double Function(double x, double y);

/// A widget that draws a mathematical function on a coordinate system with animation.
class EquationPainterWidget extends StatefulWidget {
  final MathFunction function;
  final double width;
  final double height;
  final Color graphLineColor;
  final double graphLineStrokeWidth;
  final bool showGrid;
  final bool showAxis;
  final Color gridColor;
  final double gridStrokeWidth;
  final bool animate;
  final Duration animationDuration;

  const EquationPainterWidget({
    super.key,
    required this.function,
    this.width = 300,
    this.height = 300,
    this.graphLineColor = Colors.blue,
    this.graphLineStrokeWidth = 2.0,
    this.showGrid = true,
    this.showAxis = true,
    this.gridColor = const Color(0xFFE0E0E0),
    this.gridStrokeWidth = 1.0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<EquationPainterWidget> createState() => _EquationPainterWidgetState();
}

class _EquationPainterWidgetState extends State<EquationPainterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_LineSegment>? _segments;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
    _calculateSegments();
  }

  @override
  void didUpdateWidget(EquationPainterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.function != widget.function ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _calculateSegments();
      if (widget.animate) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  void _calculateSegments() {
    final w = widget.width;
    final h = widget.height;
    const steps = 2.0;
    final start = Offset(-w / 2, h / 2);
    final end = Offset(w / 2, -h / 2);
    final segments = <_LineSegment>[];

    for (double y = start.dy; y >= end.dy; y -= steps) {
      for (double x = start.dx; x <= end.dx; x += steps) {
        final tl = Offset(x, y);
        final tr = Offset(x + steps, y);
        final bl = Offset(x, y - steps);
        final br = Offset(x + steps, y - steps);

        final tlVal = widget.function(tl.dx, tl.dy);
        final trVal = widget.function(tr.dx, tr.dy);
        final blVal = widget.function(bl.dx, bl.dy);
        final brVal = widget.function(br.dx, br.dy);

        final points = <Offset>[];

        void check(Offset p1, double v1, Offset p2, double v2) {
          if ((v1 >= 0 && v2 <= 0) || (v1 <= 0 && v2 >= 0)) {
            if (v1 == v2) return;
            final t = v1 / (v1 - v2);
            points.add(
              Offset(p1.dx + t * (p2.dx - p1.dx), p1.dy + t * (p2.dy - p1.dy)),
            );
          }
        }

        check(tl, tlVal, tr, trVal);
        check(tr, trVal, br, brVal);
        check(br, brVal, bl, blVal);
        check(bl, blVal, tl, tlVal);

        if (points.length >= 2) {
          // Normalize distance for animation (radial sweep)
          final midX = (points[0].dx + points[1].dx) / 2;
          final midY = (points[0].dy + points[1].dy) / 2;
          final dist = Offset(midX, midY).distance;
          segments.add(_LineSegment(points[0], points[1], dist));
        }
      }
    }
    // We sort segments by distance from origin to create a radial "reveal" effect
    segments.sort((a, b) => a.distance.compareTo(b.distance));
    _segments = segments;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use a Stack to separate the static background (Grid/Axis)
    // from the animated foreground (the Graph).
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Static Background Layer
          if (widget.showGrid || widget.showAxis)
            RepaintBoundary(
              child: CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _BackgroundPainter(
                  showGrid: widget.showGrid,
                  showAxis: widget.showAxis,
                  gridColor: widget.gridColor,
                  gridStrokeWidth: widget.gridStrokeWidth,
                ),
              ),
            ),

          // Animated Foreground Layer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _GraphPainter(
                  segments: _segments ?? [],
                  animationProgress: _controller.value,
                  graphLineColor: widget.graphLineColor,
                  graphLineStrokeWidth: widget.graphLineStrokeWidth,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LineSegment {
  final Offset p1;
  final Offset p2;
  final double distance;
  _LineSegment(this.p1, this.p2, this.distance);
}

/// Painter for static elements like Grid and Axis
class _BackgroundPainter extends CustomPainter {
  final bool showGrid;
  final bool showAxis;
  final Color gridColor;
  final double gridStrokeWidth;

  _BackgroundPainter({
    required this.showGrid,
    required this.showAxis,
    required this.gridColor,
    required this.gridStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint();

    // 1. Draw Grid
    if (showGrid) {
      paint.color = gridColor;
      paint.strokeWidth = gridStrokeWidth;
      for (double x = 0; x <= w; x += 20) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      }
      for (double y = 0; y <= h; y += 20) {
        canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      }
    }

    // 2. Draw Axis
    if (showAxis) {
      paint.color = Colors.black;
      paint.strokeWidth = 2.0;
      canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), paint);
      canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.showGrid != showGrid ||
        oldDelegate.showAxis != showAxis ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.gridStrokeWidth != gridStrokeWidth;
  }
}

/// Painter for the animated graph segments
class _GraphPainter extends CustomPainter {
  final List<_LineSegment> segments;
  final double animationProgress;
  final Color graphLineColor;
  final double graphLineStrokeWidth;

  _GraphPainter({
    required this.segments,
    required this.animationProgress,
    required this.graphLineColor,
    required this.graphLineStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final w = size.width;
    final h = size.height;

    // Coordinate mapping: center of canvas is (0,0)
    Offset f2m(Offset c) => Offset(w / 2 + c.dx, -c.dy + h / 2);

    final equationPaint = Paint()
      ..color = graphLineColor
      ..strokeWidth = graphLineStrokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    final countToDraw = (segments.length * animationProgress).toInt();
    for (int i = 0; i < countToDraw; i++) {
      final segment = segments[i];
      canvas.drawLine(f2m(segment.p1), f2m(segment.p2), equationPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.segments != segments ||
        oldDelegate.graphLineColor != graphLineColor ||
        oldDelegate.graphLineStrokeWidth != graphLineStrokeWidth;
  }
}
