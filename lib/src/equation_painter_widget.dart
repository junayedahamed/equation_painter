import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'equation_config.dart';
import 'background_painter.dart';
import 'graph_painter.dart';
import 'line_segment.dart';

/// [EquationPainter] is the primary widget responsible for rendering and animating
/// one or more mathematical equations on a coordinate system grid.
/// It supports interactive panning and zooming.
class EquationPainter extends StatefulWidget {
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
  final bool showAxisLabel;

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

  /// Whether to show a hint when no equations are visible.
  final bool showHint;

  /// Callback when a point on a curve is tapped.
  final void Function(double x, double y, EquationConfig config)? onPointTapped;

  const EquationPainter({
    super.key,
    required this.equations,
    this.width = double.infinity,
    this.height = double.infinity,
    this.showGrid = true,
    this.showAxis = true,
    this.gridColor = const Color(0xFFE0E0E0),
    this.gridStrokeWidth = 1.0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.animationType = AnimationType.radial,
    this.alignment = Alignment.center,
    this.showAxisLabel = true,
    this.unitsPerSquare = 100.0,
    this.labelColor = Colors.black54,
    this.xAxisColor = Colors.black54,
    this.yAxisColor = Colors.black54,
    this.interactive = true, // Enabled by default
    this.showHint = true,
    this.onPointTapped,
  });

  @override
  State<EquationPainter> createState() => _EquationPainterState();
}

class _EquationPainterState extends State<EquationPainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Float32List>? _allPoints;
  Size? _lastSize;

  // Interactive states
  late Offset _currentTranslation;
  late double _currentScale;

  // During active gestures, we lower calculation quality for 60fps performance
  bool _isInteracting = false;

  // Hover state
  Offset? _hoverPos;
  double? _hoverMathX;
  double? _hoverMathY;
  EquationConfig? _hoverConfig;

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
  void didUpdateWidget(EquationPainter oldWidget) {
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
            eq.type != oldEq.type ||
            eq.inequality != oldEq.inequality ||
            eq.fillOpacity != oldEq.fillOpacity ||
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
      if (eq.inequality != InequalityType.none) {
        final vertices = _calculateRegionFor(eq, width, height);
        final points = Float32List(vertices.length * 2);
        for (int i = 0; i < vertices.length; i++) {
          points[i * 2 + 0] = vertices[i].dx;
          points[i * 2 + 1] = vertices[i].dy;
        }
        all.add(points);
        continue;
      }
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

  List<LineSegment> _calculateSegmentsFor(
    EquationConfig config,
    double w,
    double h,
  ) {
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

    if (config.type == EquationType.polar) {
      return _calculatePolarSegments(
        config,
        w,
        h,
        pixelsPerUnit,
        originX,
        originY,
      );
    }

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

    final rawSegments = <LineSegment>[];

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
          }
          rawSegments.add(LineSegment(p1m, p2m, dist));
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

  List<LineSegment> _calculatePolarSegments(
    EquationConfig config,
    double w,
    double h,
    double pixelsPerUnit,
    double originX,
    double originY,
  ) {
    // For polar r = f(theta), we can sample theta from 0 to 2pi (or more)
    // and draw segments between the resulting (r, theta) points.
    // If it's an implicit polar equation f(r, theta) = 0, we can use marching squares
    // in the (r, theta) space.

    // Let's assume the user provides f(r, theta) = 0.
    // We'll sample r from 0 to max radius visible, and theta from 0 to 2pi.
    final double maxRadius =
        sqrt(
          pow(max(originX, w - originX), 2) + pow(max(originY, h - originY), 2),
        ) /
        pixelsPerUnit;

    final double stepR = (_isInteracting ? 8.0 : 4.0) / pixelsPerUnit;
    final double stepTheta = pi / 90; // 2 degrees

    final List<double> rValues = [];
    for (double r = 0; r <= maxRadius + stepR; r += stepR) {
      rValues.add(r);
    }

    final List<double> thetaValues = [];
    for (double theta = 0; theta <= 2 * pi + stepTheta; theta += stepTheta) {
      thetaValues.add(theta);
    }

    final int rRows = rValues.length;
    final int tCols = thetaValues.length;

    final List<double> values = List<double>.filled(rRows * tCols, 0);
    for (int r = 0; r < rRows; r++) {
      for (int t = 0; t < tCols; t++) {
        // config.function(r, theta) -> here x is r, y is theta
        final v = config.function(rValues[r], thetaValues[t]);
        values[r * tCols + t] = (v.isFinite) ? v : double.nan;
      }
    }

    final rawSegments = <LineSegment>[];

    Offset polarToCanvas(double r, double theta) {
      final x = r * cos(theta);
      final y = r * sin(theta);
      return Offset(originX + x * pixelsPerUnit, originY - y * pixelsPerUnit);
    }

    for (int r = 0; r < rRows - 1; r++) {
      for (int t = 0; t < tCols - 1; t++) {
        final double tlVal = values[r * tCols + t];
        final double trVal = values[r * tCols + t + 1];
        final double blVal = values[(r + 1) * tCols + t];
        final double brVal = values[(r + 1) * tCols + t + 1];

        if (tlVal.isNaN || trVal.isNaN || blVal.isNaN || brVal.isNaN) continue;

        final r1 = rValues[r];
        final r2 = rValues[r + 1];
        final t1 = thetaValues[t];
        final t2 = thetaValues[t + 1];

        final points = <Offset>[];

        void check(
          double ra,
          double ta,
          double va,
          double rb,
          double tb,
          double vb,
        ) {
          if ((va >= 0 && vb <= 0) || (va <= 0 && vb >= 0)) {
            if (va == vb) return;
            final interp = va / (va - vb);
            final rp = ra + interp * (rb - ra);
            final tp = ta + interp * (tb - ta);
            points.add(polarToCanvas(rp, tp));
          }
        }

        // Check edges in (r, theta) grid
        check(r1, t1, tlVal, r1, t2, trVal);
        check(r1, t2, trVal, r2, t2, brVal);
        check(r2, t2, brVal, r2, t1, blVal);
        check(r2, t1, blVal, r1, t1, tlVal);

        if (points.length >= 2) {
          // Calculation of distance for animation
          // For polar, radial might still make sense
          final p1 = points[0];
          final p2 = points[1];
          // Convert back to math coords for distance calculation
          final mx1 = (p1.dx - originX) / pixelsPerUnit;
          final my1 = (originY - p1.dy) / pixelsPerUnit;
          final mx2 = (p2.dx - originX) / pixelsPerUnit;
          final my2 = (originY - p2.dy) / pixelsPerUnit;

          double dist = 0;
          if (!_isInteracting) {
            final animType = config.animationType ?? widget.animationType;
            switch (animType) {
              case AnimationType.radial:
                dist = sqrt(mx1 * mx1 + my1 * my1);
                break;
              case AnimationType.linearX:
                dist = (mx1 + mx2) / 2;
                break;
              case AnimationType.linearY:
                dist = -(my1 + my2) / 2;
                break;
              case AnimationType.sequential:
                dist = 0;
                break;
            }
          }
          rawSegments.add(LineSegment(p1, p2, dist));
        }
      }
    }

    if (rawSegments.isEmpty) return [];
    if (_isInteracting) return rawSegments;

    final animType = config.animationType ?? widget.animationType;
    if (animType == AnimationType.sequential) {
      return _sortSegmentsSequentially(rawSegments);
    } else {
      rawSegments.sort((a, b) => a.distance.compareTo(b.distance));
      return rawSegments;
    }
  }

  List<Offset> _calculateRegionFor(EquationConfig config, double w, double h) {
    // For inequality, we sample points and check if the condition holds.
    // If it holds, we can use triangles or rectangles to fill.
    // Simplifying: we'll sample points and return vertices of small rectangles.
    // we use a 2x higher resolution than lines since we fill pixels.

    final double stepSize = _isInteracting ? 16.0 : 8.0;
    final double safeScale = _currentScale > 0 ? _currentScale : 1.0;
    final double pixelsPerUnit = 40.0 / safeScale;

    final originX = (1 + _currentTranslation.dx) * w / 2;
    final originY = (1 + _currentTranslation.dy) * h / 2;

    List<Offset> vertices = [];

    // Cartesian only for now for inequalities
    for (double y = 0; y < h; y += stepSize) {
      for (double x = 0; x < w; x += stepSize) {
        final mathX = (x - originX) / pixelsPerUnit;
        final mathY = (originY - y) / pixelsPerUnit;

        final val = config.function(mathX, mathY);
        bool inside = false;
        if (config.inequality == InequalityType.greaterThanOrEqual) {
          inside = val >= 0;
        } else if (config.inequality == InequalityType.lessThanOrEqual) {
          inside = val <= 0;
        }

        if (inside) {
          // Add 2 triangles (6 vertices) for the small square
          vertices.add(Offset(x, y));
          vertices.add(Offset(x + stepSize, y));
          vertices.add(Offset(x, y + stepSize));

          vertices.add(Offset(x + stepSize, y));
          vertices.add(Offset(x + stepSize, y + stepSize));
          vertices.add(Offset(x, y + stepSize));
        }
      }
    }
    return vertices;
  }

  List<LineSegment> _sortSegmentsSequentially(List<LineSegment> segments) {
    if (segments.isEmpty) return [];
    final sorted = <LineSegment>[];
    final unvisited = List<LineSegment>.from(segments);

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
            nextSeg = LineSegment(nextSeg.p2, nextSeg.p1, 0);
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

      // Update scale
      if (details.scale != 1.0) {
        _currentScale = (_currentScale / details.scale).clamp(0.001, 10000.0);
      }

      // Pan translation (screen space mapped to [-1, 1] alignment range)
      final dx = details.focalPointDelta.dx / (w / 2);
      final dy = details.focalPointDelta.dy / (h / 2);

      _currentTranslation += Offset(dx, dy);

      _calculateAllSegments(w, h);
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPointTapped == null ||
        _allPoints == null ||
        _lastSize == null) {
      return;
    }

    final Size size = _lastSize!;
    final double originX = (1 + _currentTranslation.dx) * size.width / 2;
    final double originY = (1 + _currentTranslation.dy) * size.height / 2;
    final double pixelsPerUnit = 40.0 / _currentScale;

    // Check distance in pixels from the tap point to all line segments.
    final tapPos = details.localPosition;
    const double threshold =
        20.0; // Increased from 12.0 for better touch target

    double minDistance = double.infinity;
    double? foundMathX;
    double? foundMathY;
    EquationConfig? foundConfig;

    for (int i = 0; i < widget.equations.length; i++) {
      final config = widget.equations[i];
      if (config.inequality != InequalityType.none) continue;

      final points = _allPoints![i];
      // For equality (lines), points has 4 floats per segment (x1, y1, x2, y2)
      if (points.length % 4 == 0) {
        for (int j = 0; j < points.length; j += 4) {
          final p1 = Offset(points[j], points[j + 1]);
          final p2 = Offset(points[j + 2], points[j + 3]);

          final dist = _distToSegment(tapPos, p1, p2);
          if (dist < threshold && dist < minDistance) {
            final t = _projectionFactor(tapPos, p1, p2);
            final closestP = Offset(
              p1.dx + t * (p2.dx - p1.dx),
              p1.dy + t * (p2.dy - p1.dy),
            );
            minDistance = dist;
            foundMathX = (closestP.dx - originX) / pixelsPerUnit;
            foundMathY = (originY - closestP.dy) / pixelsPerUnit;
            foundConfig = config;
          }
        }
      }
    }

    if (foundConfig != null) {
      widget.onPointTapped!(foundMathX!, foundMathY!, foundConfig);
    }
  }

  void _onHover(PointerHoverEvent event) {
    if (_allPoints == null || _lastSize == null) return;

    final Size size = _lastSize!;
    final double originX = (1 + _currentTranslation.dx) * size.width / 2;
    final double originY = (1 + _currentTranslation.dy) * size.height / 2;
    final double pixelsPerUnit = 40.0 / _currentScale;

    final hoverPos = event.localPosition;
    const double threshold = 12.0;

    Offset? bestCanvasPos;
    double? bestMathX;
    double? bestMathY;
    EquationConfig? bestConfig;
    double minDistance = double.infinity;

    for (int i = 0; i < widget.equations.length; i++) {
      final config = widget.equations[i];
      if (config.inequality != InequalityType.none) continue;

      final points = _allPoints![i];
      if (points.length % 4 == 0) {
        for (int j = 0; j < points.length; j += 4) {
          final p1 = Offset(points[j], points[j + 1]);
          final p2 = Offset(points[j + 2], points[j + 3]);

          final dist = _distToSegment(hoverPos, p1, p2);
          if (dist < threshold && dist < minDistance) {
            final t = _projectionFactor(hoverPos, p1, p2);
            final closestP = Offset(
              p1.dx + t * (p2.dx - p1.dx),
              p1.dy + t * (p2.dy - p1.dy),
            );
            bestCanvasPos = closestP;
            bestMathX = (closestP.dx - originX) / pixelsPerUnit;
            bestMathY = (originY - closestP.dy) / pixelsPerUnit;
            bestConfig = config;
            minDistance = dist;
          }
        }
      }
    }

    if (bestCanvasPos != _hoverPos ||
        bestMathX != _hoverMathX ||
        bestMathY != _hoverMathY) {
      if (mounted) {
        setState(() {
          _hoverPos = bestCanvasPos;
          _hoverMathX = bestMathX;
          _hoverMathY = bestMathY;
          _hoverConfig = bestConfig;
        });
      }
    }
  }

  void _onHoverExit(PointerExitEvent event) {
    if (mounted && _hoverPos != null) {
      setState(() {
        _hoverPos = null;
        _hoverMathX = null;
        _hoverMathY = null;
        _hoverConfig = null;
      });
    }
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final l2 = (a - b).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    final t =
        (((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2)
            .clamp(0.0, 1.0);
    final projection = Offset(
      a.dx + t * (b.dx - a.dx),
      a.dy + t * (b.dy - a.dy),
    );
    return (p - projection).distance;
  }

  double _projectionFactor(Offset p, Offset a, Offset b) {
    final l2 = (a - b).distanceSquared;
    if (l2 == 0) return 0.0;
    return (((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) /
            l2)
        .clamp(0.0, 1.0);
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
        final actualWidth =
            widget.width > 0 && widget.width < constraints.maxWidth
            ? widget.width
            : constraints.maxWidth;
        final actualHeight =
            widget.height > 0 && widget.height < constraints.maxHeight
            ? widget.height
            : constraints.maxHeight;

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
              widget.showHint
                  ? SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Stack(
                        children: [
                          if (widget.showGrid || widget.showAxis)
                            RepaintBoundary(
                              child: CustomPaint(
                                size: currentSize,
                                painter: BackgroundPainter(
                                  showGrid: widget.showGrid,
                                  showAxis: widget.showAxis,
                                  gridColor: widget.gridColor,
                                  gridStrokeWidth: widget.gridStrokeWidth,
                                  alignment: Alignment(
                                    _currentTranslation.dx,
                                    _currentTranslation.dy,
                                  ),
                                  showAxisLabel: widget.showAxisLabel,
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
                                painter: GraphPainter(
                                  allPoints: _allPoints ?? [],
                                  equations: widget.equations,
                                  // Draw fully immediately if user panning/zoomed
                                  animationProgress: _isInteracting
                                      ? 1.0
                                      : _controller.value,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        if (widget.showGrid || widget.showAxis)
                          RepaintBoundary(
                            child: CustomPaint(
                              size: currentSize,
                              painter: BackgroundPainter(
                                showGrid: widget.showGrid,
                                showAxis: widget.showAxis,
                                gridColor: widget.gridColor,
                                gridStrokeWidth: widget.gridStrokeWidth,
                                alignment: Alignment(
                                  _currentTranslation.dx,
                                  _currentTranslation.dy,
                                ),
                                showAxisLabel: widget.showAxisLabel,
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
                              painter: GraphPainter(
                                allPoints: _allPoints ?? [],
                                equations: widget.equations,
                                // Draw fully immediately if user panning/zoomed
                                animationProgress: _isInteracting
                                    ? 1.0
                                    : _controller.value,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
              if (_hoverPos != null)
                Positioned(
                  left: _hoverPos!.dx + 15,
                  top: _hoverPos!.dy + 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _hoverConfig?.color ?? Colors.white54,
                      ),
                    ),
                    child: Text(
                      _hoverConfig?.type == EquationType.polar
                          ? "r: ${_hoverMathX?.toStringAsFixed(2)}, θ: ${_hoverMathY?.toStringAsFixed(2)}"
                          : "x: ${_hoverMathX?.toStringAsFixed(2)}, y: ${_hoverMathY?.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        );

        if (widget.interactive) {
          return MouseRegion(
            onHover: _onHover,
            onExit: _onHoverExit,
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              onTapDown: _onTapDown,
              behavior: HitTestBehavior.opaque,
              child: ClipRect(child: content),
            ),
          );
        } else {
          return MouseRegion(
            onHover: _onHover,
            onExit: _onHoverExit,
            child: GestureDetector(
              onTapDown: _onTapDown,
              behavior: HitTestBehavior.opaque,
              child: ClipRect(child: content),
            ),
          );
        }
      },
    );
  }
}
