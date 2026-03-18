import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// [MathFunction] represents a mathematical function of two variables (x, y).
/// It returns a double value which can be used for implicit equation plotting.
typedef MathFunction = double Function(double x, double y);

/// [AnimationType] defines how the mathematical equation is revealed during the animation process.
enum AnimationType {
  /// The curve is revealed starting from the origin (0,0) and moving outwards.
  radial,

  /// The curve is revealed point-by-point following its path, creating a "hand-drawn" effect.
  sequential,

  /// The curve is revealed from the leftmost visible point to the rightmost.
  linearX,

  /// The curve is revealed from the topmost visible point to the bottom.
  linearY,
}

/// [EquationConfig] holds the configuration for a single mathematical equation in the plot.
/// It includes the [function] itself, visual properties like [color] and [strokeWidth],
/// and optional constraints like [minX], [maxX], etc.
class EquationConfig {
  /// The actual [MathFunction] to be plotted.
  final MathFunction function;

  /// The color used to draw this specific equation's curve.
  final Color color;

  /// The thickness of the curve line.
  final double strokeWidth;

  /// Optional override for the [AnimationType]. If null, the [EquationPainterWidget.animationType] is used.
  final AnimationType? animationType;

  /// Optional minimum X value (mathematical coordinates) to bound the plotting.
  final double? minX;

  /// Optional maximum X value (mathematical coordinates) to bound the plotting.
  final double? maxX;

  /// Optional minimum Y value (mathematical coordinates) to bound the plotting.
  final double? minY;

  /// Optional maximum Y value (mathematical coordinates) to bound the plotting.
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

/// [EquationPainterWidget] is the primary widget responsible for rendering and animating
/// one or more mathematical equations on a coordinate system grid.
class EquationPainterWidget extends StatefulWidget {
  /// A list of [EquationConfig] objects representing the equations to be drawn.
  final List<EquationConfig> equations;

  /// The explicit width of the widget. If not specified or invalid, it fills the [LayoutBuilder] constraints.
  final double width;

  /// The explicit height of the widget.
  final double height;

  /// Whether to display the background coordinate grid.
  final bool showGrid;

  /// Whether to display the X and Y axes.
  final bool showAxis;

  /// The color of the background grid lines.
  final Color gridColor;

  /// The stroke width of the grid lines.
  final double gridStrokeWidth;

  /// Whether to animate the revealing of the curves.
  final bool animate;

  /// The duration of the reveal animation.
  final Duration animationDuration;

  /// Whether to show numerical labels on the axes.
  final bool showNumbers;

  /// Scale factor: how many mathematical units are represented by one grid square (approx 40 pixels).
  final double unitsPerSquare;

  /// The color of the axis numbers and labels.
  final Color labelColor;

  /// The color of the X-axis line.
  final Color xAxisColor;

  /// The color of the Y-axis line.
  final Color yAxisColor;

  /// The default [AnimationType] for all equations in this widget.
  final AnimationType animationType;

  /// Where the mathematical origin (0,0) should be positioned within the widget's bounds.
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

/// [_EquationPainterWidgetState] handles the animation lifecycle and the heavy computation
/// of curve segments whenever the widget's data or size changes.
class _EquationPainterWidgetState extends State<EquationPainterWidget>
    with SingleTickerProviderStateMixin {
  /// Controller for the reveal animation.
  late AnimationController _controller;

  /// Stores pre-computed points for all equations as [Float32List] for efficient rendering.
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

    /// Check if the physical segments need recalculation (size, alignment, or equation count changed).
    bool segmentsChanged =
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.alignment != widget.alignment ||
        oldWidget.equations.length != widget.equations.length;

    /// Deep check if any specific equation logic or bounds changed.
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
      /// If only scale or duration changed, we may still need to re-calculate points.
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

  /// Iterates through every equation config to calculate its visible line segments.
  void _calculateAllSegments(double width, double height) {
    final all = <Float32List>[];
    for (final eq in widget.equations) {
      final segments = _calculateSegmentsFor(eq, width, height);

      /// We flatten the [Offset] pairs into a [Float32List] for faster [canvas.drawRawPoints] processing.
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

  /// The core logic that converts a mathematical function into visual line segments using a
  /// simplified Marching Squares approach. Scans the visible grid and finds zero-crossings.
  List<_LineSegment> _calculateSegmentsFor(
    EquationConfig config,
    double w,
    double h,
  ) {
    /// Density of samples. Lower is more detailed but slower.
    const steps = 4.0;

    /// Calculate origin projection based on [alignment].
    final originX = (1 + widget.alignment.x) * w / 2;
    final originY = (1 + widget.alignment.y) * h / 2;

    /// Ratio of pixels to mathematical units.
    final double pixelsPerUnit = 40.0 / widget.unitsPerSquare;

    /// Local helper to convert Mathematical Coordinates to Flutter Canvas Coordinates.
    Offset f2m(Offset c) =>
        Offset(originX + c.dx * pixelsPerUnit, originY - c.dy * pixelsPerUnit);

    /// Determine the visible range in math units.
    final double canvasMinX =
        -(1 + widget.alignment.x) * w / (2 * pixelsPerUnit);
    final double canvasMaxX = canvasMinX + w / pixelsPerUnit;
    final double canvasMinY =
        ((1 + widget.alignment.y) * h / 2 - h) / pixelsPerUnit;
    final double canvasMaxY = canvasMinY + h / pixelsPerUnit;

    /// Intersect canvas visibility with [EquationConfig] custom limits.
    final minX = max(canvasMinX, config.minX ?? -double.infinity);
    final maxX = min(canvasMaxX, config.maxX ?? double.infinity);
    final minY = max(canvasMinY, config.minY ?? -double.infinity);
    final maxY = min(canvasMaxY, config.maxY ?? double.infinity);

    if (minX >= maxX || minY >= maxY) return [];

    /// Generate sample coordinate lists.
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

    /// Pre-evaluate the function at every grid point to avoid redundant calls during the scanning phase.
    final List<double> values = List<double>.filled(rows * cols, 0);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        values[r * cols + c] = config.function(xValues[c], yValues[r]);
      }
    }

    final rawSegments = <_LineSegment>[];

    /// Iterate through every quad (4 adjacent points) and check for sign changes (Marching Squares).
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

        /// Linearly interpolates where the curve crosses between two points [v1] and [v2].
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

          /// Calculate a "distance" metric for sorting/animation based on the selected [AnimationType].
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
      /// Sequential sorting joins segments end-to-end for a continuous drawing effect.
      return _sortSegmentsSequentially(rawSegments);
    } else {
      /// Otherwise, sort by the calculated distance for radial/linear reveal.
      rawSegments.sort((a, b) => a.distance.compareTo(b.distance));
      return rawSegments;
    }
  }

  /// Reorders line segments such that each segment starts approximately where the previous one ended.
  /// Uses a greedy "nearest neighbor" algorithm with a search window for performance optimization.
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

        /// Optimization: Only look at nearby segments in the original list.
        /// Because they were scanned row-by-row, physical neighbors are often close indices.
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

          /// If we found an exact match or very close point, stop searching.
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
          /// If no neighbor is found within the search window, a new path starts elsewhere.
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
        /// Determine final canvas size based on widget properties and parent constraints.
        final actualWidth =
            widget.width > 0 && widget.width < constraints.maxWidth
            ? widget.width
            : constraints.maxWidth;
        final actualHeight =
            widget.height > 0 && widget.height < constraints.maxHeight
            ? widget.height
            : constraints.maxHeight;

        final currentSize = Size(actualWidth, actualHeight);

        /// If parent layout changed our size, recalculate points after the build phase.
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
              /// The Grid and Axes are painted in a separate [RepaintBoundary] so they don't
              /// redraw during the curve animation.
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

              /// The curves are drawn here and updated by the [_controller].
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

/// A simple helper class defining a single line segment with a distance used for sorting.
class _LineSegment {
  final Offset p1;
  final Offset p2;
  final double distance;
  _LineSegment(this.p1, this.p2, this.distance);
}

/// [_BackgroundPainter] is responsible for drawing non-animated elements like the grid,
/// axes, and axis labels based on the provided configuration.
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

    /// Calculate the pixel coordinate of the origin (0,0).
    final originX = (1 + alignment.x) * w / 2;
    final originY = (1 + alignment.y) * h / 2;

    /// Draw the grid if enabled.
    if (showGrid) {
      paint.color = gridColor;
      paint.strokeWidth = gridStrokeWidth;

      /// Vertical grid lines.
      for (double x = originX; x <= w; x += 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      }
      for (double x = originX - 40; x >= 0; x -= 40) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
      }

      /// Horizontal grid lines.
      for (double y = originY; y <= h; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      }
      for (double y = originY - 40; y >= 0; y -= 40) {
        canvas.drawLine(Offset(0, y), Offset(w, y), paint);
      }
    }

    /// Draw X and Y axes if enabled.
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

  /// Renders numerical labels along the X and Y axes.
  void _drawLabels(Canvas canvas, Size size, double originX, double originY) {
    final w = size.width;
    final h = size.height;

    final textStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    /// Paints a single label string at a given offset while ensuring it stays visible.
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

        /// Wrap logic to keep labels on screen.
        if (dy + tp.height > h) dy -= (tp.height + 8);
      } else {
        dx += 4;
        dy -= tp.height / 2;
        if (dx + tp.width > w) dx -= (tp.width + 8);
      }

      tp.paint(canvas, Offset(dx, dy));
    }

    /// Iteratively draw X-axis labels.
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

    /// Iteratively draw Y-axis labels.
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

  /// Utility to format double values to shorter strings.
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

/// [_GraphPainter] is the high-performance painter responsible for drawing the actual curves.
class _GraphPainter extends CustomPainter {
  /// All pre-computed curve points.
  final List<Float32List> allPoints;

  /// Original configurations for styles like color/stroke.
  final List<EquationConfig> equations;

  /// Current animation state (0.0 to 1.0).
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

      /// [drawRawPoints] is used here for extreme speed compared to [drawPath].
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
  /// Simple clarity extension.
  double toFloat() => this;
}
