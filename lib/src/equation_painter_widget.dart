import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

typedef MathFunction = double Function(double x, double y);

/// Defines how the equation is revealed during animation.
enum AnimationType {
  /// Revealed from the center outwards.
  radial,

  /// Revealed point-by-point following the curve's path (hand-drawn effect).
  sequential,

  /// Revealed from left to right.
  linearX,

  /// Revealed from top to bottom.
  linearY,
}

/// Configuration for a single mathematical equation in the plot.
class EquationConfig {
  final MathFunction function;
  final Color color;
  final double strokeWidth;

  /// Optional override for the animation type. If null, the widget's default is used.
  final AnimationType? animationType;

  /// Optional limits for the x-variable in mathematical coordinates.
  final double? minX;
  final double? maxX;

  /// Optional limits for the y-variable in mathematical coordinates.
  final double? minY;
  final double? maxY;

  const EquationConfig({
    required this.function,
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
    this.animationType,
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
  });
}

/// A widget that draws multiple mathematical functions on a coordinate system with animation.
class EquationPainterWidget extends StatefulWidget {
  final List<EquationConfig> equations;
  final double width;
  final double height;
  final bool showGrid;
  final bool showAxis;
  final Color gridColor;
  final double gridStrokeWidth;
  final bool animate;
  final Duration animationDuration;

  /// Whether to show the coordinate numbers on the grid.
  final bool showNumbers;

  /// How many mathematical units one grid square (40 pixels) represents.
  /// Defaults to 1.0.
  final double unitsPerSquare;

  /// The color of the coordinate numbers.
  final Color labelColor;

  /// The color of the X-axis (horizontal line).
  final Color xAxisColor;

  /// The color of the Y-axis (vertical line).
  final Color yAxisColor;

  /// The style of animation used to reveal the graph.
  final AnimationType animationType;

  /// Where the origin (0,0) is located on the canvas.
  /// Defaults to [Alignment.center].
  final Alignment alignment;

  const EquationPainterWidget({
    super.key,
    required this.equations,
    this.width = 300,
    this.height = 300,
    this.showGrid = true,
    this.showAxis = true,
    this.gridColor = const Color(0xFFE0E0E0),
    this.gridStrokeWidth = 1.0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.animationType = AnimationType.radial,
    this.alignment = Alignment.center,
    this.showNumbers = true,
    this.unitsPerSquare = 1.0,
    this.labelColor = Colors.black54,
    this.xAxisColor = Colors.black54,
    this.yAxisColor = Colors.black54,
  });

  @override
  State<EquationPainterWidget> createState() => _EquationPainterWidgetState();
}

class _EquationPainterWidgetState extends State<EquationPainterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Float32List>? _allPoints;

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
  }

  @override
  void didUpdateWidget(EquationPainterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool segmentsChanged =
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.alignment != widget.alignment ||
        oldWidget.equations.length != widget.equations.length;

    if (!segmentsChanged) {
      for (int i = 0; i < widget.equations.length; i++) {
        final eq = widget.equations[i];
        final oldEq = oldWidget.equations[i];
        if (eq.function != oldEq.function ||
            eq.animationType != oldEq.animationType ||
            eq.minX != oldEq.minX ||
            eq.maxX != oldEq.maxX ||
            eq.minY != oldEq.minY ||
            eq.maxY != oldEq.maxY) {
          segmentsChanged = true;
          break;
        }
      }
    }

    if (segmentsChanged) {
      _calculateAllSegments(
        _lastSize?.width ?? widget.width,
        _lastSize?.height ?? widget.height,
      );
      if (widget.animate) {
        _controller.reset();
        _controller.forward();
      }
    } else if (oldWidget.animationDuration != widget.animationDuration ||
        oldWidget.unitsPerSquare != widget.unitsPerSquare) {
      if (oldWidget.unitsPerSquare != widget.unitsPerSquare) {
        _calculateAllSegments(
          _lastSize?.width ?? widget.width,
          _lastSize?.height ?? widget.height,
        );
      }
      _controller.duration = widget.animationDuration;
    }
  }

  Size? _lastSize;

  void _calculateAllSegments(double width, double height) {
    final all = <Float32List>[];
    for (final eq in widget.equations) {
      final segments = _calculateSegmentsFor(eq, width, height);
      final points = Float32List(segments.length * 4);
      for (int i = 0; i < segments.length; i++) {
        points[i * 4 + 0] = segments[i].p1.dx.toFloat();
        points[i * 4 + 1] = segments[i].p1.dy.toFloat();
        points[i * 4 + 2] = segments[i].p2.dx.toFloat();
        points[i * 4 + 3] = segments[i].p2.dy.toFloat();
      }
      all.add(points);
    }
    _allPoints = all;
  }

  List<_LineSegment> _calculateSegmentsFor(
    EquationConfig config,
    double w,
    double h,
  ) {
    const steps = 4.0;

    final originX = (1 + widget.alignment.x) * w / 2;
    final originY = (1 + widget.alignment.y) * h / 2;

    final double pixelsPerUnit = 40.0 / widget.unitsPerSquare;

    /// Flutter to math canvas Conversion [Math -> Flutter]
    Offset f2m(Offset c) =>
        Offset(originX + c.dx * pixelsPerUnit, originY - c.dy * pixelsPerUnit);

    // Visible canvas range in mathematical units
    final double canvasMinX =
        -(1 + widget.alignment.x) * w / (2 * pixelsPerUnit);
    final double canvasMaxX = canvasMinX + w / pixelsPerUnit;
    final double canvasMinY =
        ((1 + widget.alignment.y) * h / 2 - h) / pixelsPerUnit;
    final double canvasMaxY = canvasMinY + h / pixelsPerUnit;

    // Final scanning range (intersection of canvas and config limits)
    final minX = max(canvasMinX, config.minX ?? -double.infinity);
    final maxX = min(canvasMaxX, config.maxX ?? double.infinity);
    final minY = max(canvasMinY, config.minY ?? -double.infinity);
    final maxY = min(canvasMaxY, config.maxY ?? double.infinity);

    // If limits make it invisible, return empty
    if (minX >= maxX || minY >= maxY) return [];

    final double stepX = steps / pixelsPerUnit;
    final List<double> xValues = [];
    for (double x = minX; x <= maxX + stepX; x += stepX) {
      xValues.add(x);
    }

    final double stepY = steps / pixelsPerUnit;
    final List<double> yValues = [];
    for (double y = minY; y <= maxY + stepY; y += stepY) {
      yValues.add(y);
    }

    final int rows = yValues.length;
    final int cols = xValues.length;

    final List<double> values = List<double>.filled(rows * cols, 0);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        values[r * cols + c] = config.function(xValues[c], yValues[r]);
      }
    }

    final rawSegments = <_LineSegment>[];

    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols - 1; c++) {
        final double tlVal = values[r * cols + c];
        final double trVal = values[r * cols + c + 1];
        final double blVal = values[(r + 1) * cols + c];
        final double brVal = values[(r + 1) * cols + c + 1];

        if (tlVal.isNaN || trVal.isNaN || blVal.isNaN || brVal.isNaN) continue;

        final Offset tl = Offset(xValues[c], yValues[r]);
        final Offset tr = Offset(xValues[c + 1], yValues[r]);
        final Offset bl = Offset(xValues[c], yValues[r + 1]);
        final Offset br = Offset(xValues[c + 1], yValues[r + 1]);

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
          final p1m = f2m(points[0]);
          final p2m = f2m(points[1]);

          double dist = 0;
          final animType = config.animationType ?? widget.animationType;
          switch (animType) {
            case AnimationType.radial:
              dist =
                  (points[0].dx + points[1].dx).abs() +
                  (points[0].dy + points[1].dy).abs();
              break;
            case AnimationType.linearX:
              dist = (points[0].dx + points[1].dx) / 2;
              break;
            case AnimationType.linearY:
              dist = -((points[0].dy + points[1].dy) / 2);
              break;
            case AnimationType.sequential:
              dist = 0;
              break;
          }
          rawSegments.add(_LineSegment(p1m, p2m, dist));
        }
      }
    }

    if (rawSegments.isEmpty) return [];

    final animType = config.animationType ?? widget.animationType;
    if (animType == AnimationType.sequential) {
      return _sortSegmentsSequentially(rawSegments);
    } else {
      rawSegments.sort((a, b) => a.distance.compareTo(b.distance));
      return rawSegments;
    }
  }

  List<_LineSegment> _sortSegmentsSequentially(List<_LineSegment> segments) {
    if (segments.isEmpty) return [];
    final sorted = <_LineSegment>[];
    final unvisited = List<_LineSegment>.from(segments);

    while (unvisited.isNotEmpty) {
      var current = unvisited.removeAt(0);
      sorted.add(current);

      bool foundNext = true;
      while (foundNext && unvisited.isNotEmpty) {
        foundNext = false;
        Offset lastPoint = current.p2;

        int bestIdx = -1;
        bool reversed = false;
        double minFoundDist = 16.0;

        // Optimization: Neighbors are likely nearby in the original list due to grid scanning.
        // We limit search to a window to avoid O(N^2) on large datasets.
        final int searchLimit = min(unvisited.length, 1000);
        for (int i = 0; i < searchLimit; i++) {
          final seg = unvisited[i];
          double d1 = (seg.p1 - lastPoint).distanceSquared;
          double d2 = (seg.p2 - lastPoint).distanceSquared;

          if (d1 < minFoundDist) {
            minFoundDist = d1;
            bestIdx = i;
            reversed = false;
          } else if (d2 < minFoundDist) {
            minFoundDist = d2;
            bestIdx = i;
            reversed = true;
          }
          if (minFoundDist < 0.1) break;
        }

        if (bestIdx != -1) {
          var nextSeg = unvisited.removeAt(bestIdx);
          if (reversed) {
            nextSeg = _LineSegment(nextSeg.p2, nextSeg.p1, 0);
          }
          sorted.add(nextSeg);
          current = nextSeg;
          foundNext = true;
        } else {
          // If no neighbor found in window, fallback to first unvisited item
          // to start a new disconnected path segment.
          // This prevents the algorithm from being O(N^2) and handles discontinuities.
          break;
        }
      }
    }
    return sorted;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualWidth =
            widget.width > 0 && widget.width < constraints.maxWidth
            ? widget.width
            : constraints.maxWidth;
        final actualHeight =
            widget.height > 0 && widget.height < constraints.maxHeight
            ? widget.height
            : constraints.maxHeight;

        final currentSize = Size(actualWidth, actualHeight);

        // Proactively recalculate if parent constraints changed the size
        if (_lastSize != currentSize) {
          _lastSize = currentSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _calculateAllSegments(actualWidth, actualHeight);
              });
            }
          });
        }

        return SizedBox(
          width: actualWidth,
          height: actualHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showGrid || widget.showAxis)
                RepaintBoundary(
                  child: CustomPaint(
                    size: currentSize,
                    painter: _BackgroundPainter(
                      showGrid: widget.showGrid,
                      showAxis: widget.showAxis,
                      gridColor: widget.gridColor,
                      gridStrokeWidth: widget.gridStrokeWidth,
                      alignment: widget.alignment,
                      showNumbers: widget.showNumbers,
                      unitsPerSquare: widget.unitsPerSquare,
                      labelColor: widget.labelColor,
                      xAxisColor: widget.xAxisColor,
                      yAxisColor: widget.yAxisColor,
                    ),
                  ),
                ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    size: currentSize,
                    painter: _GraphPainter(
                      allPoints: _allPoints ?? [],
                      equations: widget.equations,
                      animationProgress: _controller.value,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LineSegment {
  final Offset p1;
  final Offset p2;
  final double distance;
  _LineSegment(this.p1, this.p2, this.distance);
}

class _BackgroundPainter extends CustomPainter {
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

  _BackgroundPainter({
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

    if (showGrid) {
      paint.color = gridColor;
      paint.strokeWidth = gridStrokeWidth;

      for (double x = originX; x <= w; x += 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      }
      for (double x = originX - 40; x >= 0; x -= 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      }

      for (double y = originY; y <= h; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      }
      for (double y = originY - 40; y >= 0; y -= 40) {
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

      // Offset for positioning
      double dx = pos.dx;
      double dy = pos.dy;

      if (isX) {
        dx -= tp.width / 2;
        dy += 4; // Below the axis
        // Keep within vertical bounds
        if (dy + tp.height > h) dy -= (tp.height + 8);
      } else {
        dx += 4; // Right of the axis
        dy -= tp.height / 2;
        // Keep within horizontal bounds
        if (dx + tp.width > w) dx -= (tp.width + 8);
      }

      tp.paint(canvas, Offset(dx, dy));
    }

    // X axis labels
    int xCount = 1;
    for (double x = originX + 40; x <= w; x += 40) {
      final val = xCount * unitsPerSquare;
      drawText(_format(val), Offset(x, originY), isX: true);
      xCount++;
    }
    xCount = -1;
    for (double x = originX - 40; x >= 0; x -= 40) {
      final val = xCount * unitsPerSquare;
      drawText(_format(val), Offset(x, originY), isX: true);
      xCount--;
    }

    // Y axis labels
    int yCount = 1;
    for (double y = originY - 40; y >= 0; y -= 40) {
      final val = yCount * unitsPerSquare;
      drawText(_format(val), Offset(originX, y), isX: false);
      yCount++;
    }
    yCount = -1;
    for (double y = originY + 40; y <= h; y += 40) {
      final val = yCount * unitsPerSquare;
      drawText(_format(val), Offset(originX, y), isX: false);
      yCount--;
    }
  }

  String _format(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
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

class _GraphPainter extends CustomPainter {
  final List<Float32List> allPoints;
  final List<EquationConfig> equations;
  final double animationProgress;

  _GraphPainter({
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
      final points = allPoints[i];
      final config = equations[i];
      paint.color = config.color;
      paint.strokeWidth = config.strokeWidth;

      final totalSegments = points.length ~/ 4;
      final countToDraw = (totalSegments * animationProgress).toInt();
      if (countToDraw <= 0) continue;

      // Use drawRawPoints with Float32List for maximum performance.
      // We use sublistView to avoid copying data.
      final pointsToDraw = Float32List.sublistView(points, 0, countToDraw * 4);
      canvas.drawRawPoints(ui.PointMode.lines, pointsToDraw, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.allPoints != allPoints ||
        oldDelegate.equations != equations;
  }
}

extension on double {
  double toFloat() => this; // Double is already float in Dart, but for clarity
}
