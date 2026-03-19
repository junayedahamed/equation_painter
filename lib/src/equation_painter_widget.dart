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
/// It supports interactive panning and zooming.
class EquationPainterWidget extends StatefulWidget {
  /// A list of [EquationConfig] objects representing the equations to be drawn.
  final List<EquationConfig> equations;

  /// The explicit width of the widget. Values <= 0 fill the [LayoutBuilder] constraints.
  final double width;

  /// The explicit height of the widget. Values <= 0 fill the [LayoutBuilder] constraints.
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

  /// Initial scale factor: how many mathematical units are represented by one grid square (~40 pixels).
  final double unitsPerSquare;

  /// The color of the axis numbers and labels.
  final Color labelColor;

  /// The color of the X-axis line.
  final Color xAxisColor;

  /// The color of the Y-axis line.
  final Color yAxisColor;

  /// The default [AnimationType] for all equations in this widget.
  final AnimationType animationType;

  /// Initial alignment of the mathematical origin (0,0) within the widget.
  final Alignment alignment;
  
  /// Whether to enable interactive pan and zoom gestures.
  final bool interactive;

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
    this.interactive = true, // Enabled by default
  });

  @override
  State<EquationPainterWidget> createState() => _EquationPainterWidgetState();
}

class _EquationPainterWidgetState extends State<EquationPainterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Float32List>? _allPoints;
  Size? _lastSize;

  // Interactive states
  late Offset _currentTranslation;
  late double _currentScale;
  
  // During active gestures, we lower calculation quality for 60fps performance
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _currentTranslation = Offset(widget.alignment.x, widget.alignment.y);
    _currentScale = widget.unitsPerSquare > 0 ? widget.unitsPerSquare : 1.0;
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lastSize != null) {
        setState(() {
          _calculateAllSegments(_lastSize!.width, _lastSize!.height);
        });
      }
    });
  }

  @override
  void didUpdateWidget(EquationPainterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }

    if (!oldWidget.animate && widget.animate) {
      _controller.reset();
      _controller.forward();
    }

    bool externalStateReset = 
        oldWidget.alignment != widget.alignment ||
        oldWidget.unitsPerSquare != widget.unitsPerSquare;
        
    if (externalStateReset) {
      _currentTranslation = Offset(widget.alignment.x, widget.alignment.y);
      _currentScale = widget.unitsPerSquare > 0 ? widget.unitsPerSquare : 1.0;
    }

    bool segmentsChanged =
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        externalStateReset ||
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
      setState(() {
        _calculateAllSegments(
          _lastSize?.width ?? widget.width,
          _lastSize?.height ?? widget.height,
        );
      });
      if (widget.animate) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  void _calculateAllSegments(double width, double height) {
    if (width <= 0 || height <= 0) return;

    final all = <Float32List>[];
    for (final eq in widget.equations) {
      final segments = _calculateSegmentsFor(eq, width, height);

      final points = Float32List(segments.length * 4);
      for (int i = 0; i < segments.length; i++) {
        points[i * 4 + 0] = segments[i].p1.dx;
        points[i * 4 + 1] = segments[i].p1.dy;
        points[i * 4 + 2] = segments[i].p2.dx;
        points[i * 4 + 3] = segments[i].p2.dy;
      }
      all.add(points);
    }
    _allPoints = all;
  }

  List<_LineSegment> _calculateSegmentsFor(EquationConfig config, double w, double h) {
    // Dynamic resolution: 4.0 normally, 8.0 during interaction for faster calc
    final double steps = _isInteracting ? 8.0 : 4.0;

    final double safeUnitsPerSquare = _currentScale > 0 ? _currentScale : 1.0;

    // Convert internal alignment [-1, 1] to pixel offset from center
    // We treat translation x/y as logical alignment equivalents
    final originX = (1 + _currentTranslation.dx) * w / 2;
    final originY = (1 + _currentTranslation.dy) * h / 2;

    final double pixelsPerUnit = 40.0 / safeUnitsPerSquare;

    Offset mathToCanvas(Offset c) =>
        Offset(originX + c.dx * pixelsPerUnit, originY - c.dy * pixelsPerUnit);

    final double canvasMinX = -originX / pixelsPerUnit;
    final double canvasMaxX = (w - originX) / pixelsPerUnit;
    final double canvasMinY = (originY - h) / pixelsPerUnit;
    final double canvasMaxY = originY / pixelsPerUnit;

    final minX = max(canvasMinX, config.minX ?? -double.infinity);
    final maxX = min(canvasMaxX, config.maxX ?? double.infinity);
    final minY = max(canvasMinY, config.minY ?? -double.infinity);
    final maxY = min(canvasMaxY, config.maxY ?? double.infinity);

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

    if (rows < 2 || cols < 2) return [];

    final List<double> values = List<double>.filled(rows * cols, 0);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final v = config.function(xValues[c], yValues[r]);
        values[r * cols + c] = (v.isFinite) ? v : double.nan;
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
          final p1m = mathToCanvas(points[0]);
          final p2m = mathToCanvas(points[1]);

          double dist = 0;
          if (!_isInteracting) {
            final animType = config.animationType ?? widget.animationType;
            switch (animType) {
              case AnimationType.radial:
                dist = (points[0].dx + points[1].dx).abs() + (points[0].dy + points[1].dy).abs();
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
          }
          rawSegments.add(_LineSegment(p1m, p2m, dist));
        }
      }
    }

    if (rawSegments.isEmpty) return [];

    // Skip heavy sorting if interacting
    if (_isInteracting) return rawSegments;

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
        final Offset lastPoint = current.p2;

        int bestIdx = -1;
        bool reversed = false;
        double minFoundDist = 16.0;

        final int searchLimit = min(unvisited.length, 1000);
        for (int i = 0; i < searchLimit; i++) {
          final seg = unvisited[i];
          final double d1 = (seg.p1 - lastPoint).distanceSquared;
          final double d2 = (seg.p2 - lastPoint).distanceSquared;

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
          break;
        }
      }
    }
    return sorted;
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (!widget.interactive) return;
    _isInteracting = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.interactive || _lastSize == null) return;
    
    setState(() {
      final w = _lastSize!.width;
      final h = _lastSize!.height;

      // Pan translation (screen space mapped to [-1, 1] alignment range)
      final dx = details.focalPointDelta.dx / (w / 2);
      final dy = details.focalPointDelta.dy / (h / 2);
      
      _currentTranslation += Offset(dx, dy);

      _calculateAllSegments(w, h);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (!widget.interactive) return;
    setState(() {
      _isInteracting = false;
      // Recompute at full resolution when interaction ends
      if (_lastSize != null) {
        _calculateAllSegments(_lastSize!.width, _lastSize!.height);
      }
    });
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
        final actualWidth = widget.width > 0 && widget.width < constraints.maxWidth ? widget.width : constraints.maxWidth;
        final actualHeight = widget.height > 0 && widget.height < constraints.maxHeight ? widget.height : constraints.maxHeight;

        final currentSize = Size(actualWidth, actualHeight);

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

        Widget content = SizedBox(
          width: actualWidth,
          height: actualHeight,
          child: Stack(
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
                      alignment: Alignment(_currentTranslation.dx, _currentTranslation.dy),
                      showNumbers: widget.showNumbers,
                      unitsPerSquare: _currentScale,
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
                      // Draw fully immediately if user panning/zoomed
                      animationProgress: _isInteracting ? 1.0 : _controller.value,
                    ),
                  );
                },
              ),
            ],
          ),
        );

        if (widget.interactive) {
          return GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            behavior: HitTestBehavior.opaque,
            child: ClipRect(child: content),
          );
        } else {
          return ClipRect(child: content);
        }
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
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.allPoints != allPoints ||
        oldDelegate.equations != equations;
  }
}
