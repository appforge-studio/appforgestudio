import 'package:flutter/material.dart';
import 'dart:math';
import 'models.dart';
import 'vector_utils.dart';

enum DragType { anchor, handleIn, handleOut }

class VectorEditor extends StatefulWidget {
  final String pathData;
  final double width;
  final double height;
  final Function(String) onPathChanged;
  final VoidCallback? onClose;
  final double padding;
  final Color color;
  final double canvasScale;

  const VectorEditor({
    super.key,
    required this.pathData,
    required this.width,
    required this.height,
    required this.onPathChanged,
    this.onClose,
    this.color = Colors.black,
    this.canvasScale = 1.0,
    this.padding = 20.0,
  });

  @override
  State<VectorEditor> createState() => _VectorEditorState();
}

class _VectorEditorState extends State<VectorEditor> {
  late List<PathNode> _nodes;
  Rect _bounds = Rect.zero;

  double _scale = 1.0;
  Offset _translate = Offset.zero;

  // Drag state
  String? _dragTargetId;
  DragType? _dragType;
  // We store the original state of the node being dragged to calculate deltas
  PathNode? _dragNodeStart;
  Offset? _dragStartLocalPos;

  String? _originalSvg;

  @override
  void initState() {
    super.initState();
    if (widget.pathData.trim().startsWith('<svg')) {
      _originalSvg = widget.pathData;
    }
    _parseAndCalculate();
  }

  @override
  void didUpdateWidget(VectorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pathData != oldWidget.pathData) {
      if (widget.pathData.trim().startsWith('<svg')) {
        _originalSvg = widget.pathData;
      } else {
        _originalSvg = null;
      }
    }

    if (widget.pathData != oldWidget.pathData ||
        widget.width != oldWidget.width ||
        widget.height != oldWidget.height ||
        widget.padding != oldWidget.padding) {
      if (_dragTargetId == null) {
        // Only update from source if not dragging
        _parseAndCalculate();
      } else {
        // Just recalc transform if size changed
        _calculateTransform();
      }
    } else if (widget.canvasScale != oldWidget.canvasScale) {
      // Force repaint if zoom changed
    }
  }

  void _parseAndCalculate() {
    _nodes = parseSVGPath(widget.pathData);
    if (_nodes.isEmpty) {
      // Fallback for empty path
      _nodes.add(
        PathNode(
          id: generateId(),
          position: const Offset(12, 12),
          handleIn: const Offset(12, 12),
          handleOut: const Offset(12, 12),
          isCurve: false,
          isMove: true,
        ),
      );
    }
    _bounds = getBounds(_nodes);
    _calculateTransform();
  }

  void _notifyPathChanged() {
    final newPathD = formatPathD(_nodes, true);

    if (_originalSvg != null) {
      // Inject back into SVG
      // Regex to find d attribute
      // checks for d=" anything "
      final newSvg = _originalSvg!.replaceFirst(
        RegExp(r'd="[^"]+"'),
        'd="$newPathD"',
      );
      widget.onPathChanged(newSvg);
    } else {
      widget.onPathChanged(newPathD);
    }
  }

  void _calculateTransform() {
    // Fit bounds into widget size with checks
    if (_bounds.isEmpty) return;

    // Use provided padding
    final double padding = widget.padding;
    final double availW = widget.width - padding * 2;
    final double availH = widget.height - padding * 2;

    double contentW = _bounds.width;
    double contentH = _bounds.height;

    // Avoid div by zero
    if (contentW < 1) contentW = 1;
    if (contentH < 1) contentH = 1;

    final double scaleX = availW / contentW;
    final double scaleY = availH / contentH;

    _scale = min(scaleX, scaleY);

    // Center it
    final double centerX = _bounds.left + _bounds.width / 2;
    final double centerY = _bounds.top + _bounds.height / 2;

    final double widgetCenterX = widget.width / 2;
    final double widgetCenterY = widget.height / 2;

    // translate so that center of bounds is at center of widget
    // ScreenX = (WorldX * scale) + transX
    // transX = ScreenX - WorldX * scale
    _translate = Offset(
      widgetCenterX - centerX * _scale,
      widgetCenterY - centerY * _scale,
    );
  }

  Offset _toWorld(Offset local) {
    return (local - _translate) / _scale;
  }

  void _handlePanStart(DragStartDetails details) {
    final worldPos = _toWorld(details.localPosition);
    // Hit radius should be constant screen pixels (e.g. 10px) / scale
    // Also divide by canvasScale to keep it constant screen size in zoom?
    // Actually hit testing depends on where we click.
    // If controls are small on screen, hit radius should match visual size.
    final double hitRadius = 10.0 / (_scale * widget.canvasScale);

    // Check hit
    // Check handles first (if selected? For now all visible)
    for (final node in _nodes) {
      if (node.isCurve) {
        if ((node.handleIn - worldPos).distance < hitRadius) {
          _startDrag(node, DragType.handleIn, details.localPosition);
          return;
        }
        if ((node.handleOut - worldPos).distance < hitRadius) {
          _startDrag(node, DragType.handleOut, details.localPosition);
          return;
        }
      }

      if ((node.position - worldPos).distance < hitRadius) {
        _startDrag(node, DragType.anchor, details.localPosition);
        return;
      }
    }
  }

  void _startDrag(PathNode node, DragType type, Offset pos) {
    setState(() {
      _dragTargetId = node.id;
      _dragType = type;
      _dragNodeStart = node; // immutable copy
      _dragStartLocalPos = pos;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragTargetId == null ||
        _dragNodeStart == null ||
        _dragStartLocalPos == null)
      return;

    final index = _nodes.indexWhere((n) => n.id == _dragTargetId);
    if (index == -1) return;

    final startWorld = _toWorld(_dragStartLocalPos!);
    final currWorld = _toWorld(details.localPosition);
    final delta = currWorld - startWorld;

    final original = _dragNodeStart!;
    PathNode updated = original;

    if (_dragType == DragType.anchor) {
      updated = original.copyWith(
        position: original.position + delta,
        handleIn: original.handleIn + delta,
        handleOut: original.handleOut + delta,
      );
    } else if (_dragType == DragType.handleIn) {
      updated = original.copyWith(
        handleIn: original.handleIn + delta,
        isCurve: true,
      );
      // Mirror handleOut if smooth? For now independent like in reference
    } else if (_dragType == DragType.handleOut) {
      updated = original.copyWith(
        handleOut: original.handleOut + delta,
        isCurve: true,
      );
    }

    setState(() {
      _nodes[index] = updated;
    });

    _notifyPathChanged();
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _dragTargetId = null;
      _dragType = null;
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final worldPos = _toWorld(details.localPosition);
    final double hitRadius = 10.0 / (_scale * widget.canvasScale);

    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      if ((node.position - worldPos).distance < hitRadius) {
        // Toggle curve
        _toggleCurve(i);
        return;
      }
    }
  }

  void _toggleCurve(int index) {
    final node = _nodes[index];
    final bool willBeCurve = !node.isCurve;

    PathNode newNode = node.copyWith(isCurve: willBeCurve);

    if (willBeCurve) {
      // Smooth logic: heuristic using neighbors
      // Prev and Next
      final prev = _nodes[(index - 1 + _nodes.length) % _nodes.length];
      final next = _nodes[(index + 1) % _nodes.length];

      double angle = 0;
      // Simple angle based on prev/next
      final dx = next.position.dx - prev.position.dx;
      final dy = next.position.dy - prev.position.dy;
      if (dx != 0 || dy != 0) {
        angle = atan2(dy, dx);
      }

      final dist = 10.0; // arbitrary handle length
      final hIn = Offset(
        node.position.dx - cos(angle) * dist,
        node.position.dy - sin(angle) * dist,
      );
      final hOut = Offset(
        node.position.dx + cos(angle) * dist,
        node.position.dy + sin(angle) * dist,
      );

      newNode = newNode.copyWith(handleIn: hIn, handleOut: hOut);
    } else {
      // Collapse to anchor
      newNode = newNode.copyWith(
        handleIn: node.position,
        handleOut: node.position,
      );
    }

    setState(() {
      _nodes[index] = newNode;
    });
    _notifyPathChanged();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onDoubleTapDown: _handleDoubleTapDown,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.transparent,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(widget.width, widget.height),
              painter: VectorEditorPainter(
                nodes: _nodes,
                scale: _scale,
                translate: _translate,
                fillColor: widget.color,
                canvasScale: widget.canvasScale,
              ),
            ),
            if (widget.onClose != null)
              // Close button removed as per request
              // We rely on external clicks to close
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class VectorEditorPainter extends CustomPainter {
  final List<PathNode> nodes;
  final double scale;
  final Offset translate;
  final Color fillColor;
  final double canvasScale;

  VectorEditorPainter({
    required this.nodes,
    required this.scale,
    required this.translate,
    required this.fillColor,
    this.canvasScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(translate.dx, translate.dy);
    canvas.scale(scale);

    // Constant screen width: Divide by (scale * canvasScale)
    // Desired width: 1.0 logical pixel
    final double strokeWidth = 1.0 / (scale * canvasScale);
    final double handleStrokeWidth = 0.5 / (scale * canvasScale);

    final Paint linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final Paint anchorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.fill;

    final Paint anchorStrokePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Paint handleLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = handleStrokeWidth
      ..style = PaintingStyle.stroke;

    final Paint handleDotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    if (nodes.isEmpty) {
      canvas.restore();
      return;
    }

    // Draw Path
    final path = Path();
    // Move to first point
    if (nodes.isNotEmpty) {
      path.moveTo(nodes[0].position.dx, nodes[0].position.dy);
    }

    for (int i = 1; i < nodes.length; i++) {
      final curr = nodes[i];

      if (curr.isMove) {
        // If we hit a move, we might want to close the previous subpath visually?
        // And then move to new pos.
        // For now just move.
        path.moveTo(curr.position.dx, curr.position.dy);
        continue;
      }

      final prev = nodes[i - 1];

      if (prev.isCurve || curr.isCurve) {
        path.cubicTo(
          prev.handleOut.dx,
          prev.handleOut.dy,
          curr.handleIn.dx,
          curr.handleIn.dy,
          curr.position.dx,
          curr.position.dy,
        );
      } else {
        path.lineTo(curr.position.dx, curr.position.dy);
      }
    }

    // Close it (assume icon closed)
    // Complex close logic: If we have multiple subpaths, we should close each?
    // Current simple logic just closes the whole path, which usually means
    // closing the last subpath back to its own start intersection or just closing the path object.
    // In Flutter Path, .close() closes the current subpath.
    if (nodes.length > 1) {
      // We can iterate and find ends?
      // Simplify: The svg rendering with close() will close the last subpath.
      // What about intermediate subpaths? Explicit Z command handling would be better.
      // Since we don't store explicit 'Z' command in node, we rely on implicit closure if needed.
      // But the user requested "Unnecessary connection lines".
      // The original issue is likely that we were drawing a LINE to the next M point.
      // By using path.moveTo, we break that line.

      // If we want to fully close loops visually:
      // For now, let's keep it simple: just close the last one if needed.
      path.close();
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    final double anchorRadius = 3.5 / (scale * canvasScale);
    final double handleRadius = 2.0 / (scale * canvasScale);

    // Draw Controls
    for (final node in nodes) {
      // Handles
      if (node.isCurve) {
        canvas.drawLine(node.position, node.handleIn, handleLinePaint);
        canvas.drawLine(node.position, node.handleOut, handleLinePaint);

        canvas.drawCircle(node.handleIn, handleRadius, handleDotPaint);
        canvas.drawCircle(node.handleOut, handleRadius, handleDotPaint);
      }

      // Anchor
      canvas.drawCircle(node.position, anchorRadius, anchorPaint);
      canvas.drawCircle(node.position, anchorRadius, anchorStrokePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VectorEditorPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.scale != scale ||
        oldDelegate.translate != translate ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.canvasScale != canvasScale;
  }
}
