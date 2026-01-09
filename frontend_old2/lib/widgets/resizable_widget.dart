import 'dart:convert';
import 'package:dynamic_widget/dynamic_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/debouncer.dart';

class ResizableWidget extends StatefulWidget {
  final String widgetId;
  final Widget child;
  final double width;
  final double height;
  final ClickListener? listener;

  const ResizableWidget({
    super.key,
    required this.widgetId,
    required this.child,
    required this.width,
    required this.height,
    this.listener,
  });

  @override
  State<ResizableWidget> createState() => _ResizableWidgetState();
}

class _ResizableWidgetState extends State<ResizableWidget> {
  // These will store the state at the beginning of a drag operation.
  double? _initialWidth;
  double? _initialHeight;
  final Debouncer _debouncer = Debouncer(delay: Duration(microseconds: 100));
  Offset? _dragGlobalPosition;

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragGlobalPosition = details.globalPosition;
      _initialWidth = widget.width;
      _initialHeight = widget.height;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, String corner) {
    if (_dragGlobalPosition == null ||
        _initialWidth == null ||
        _initialHeight == null)
      return;

    final delta = details.globalPosition - _dragGlobalPosition!;

    double newWidth = _initialWidth!;
    double newHeight = _initialHeight!;

    switch (corner) {
      case 'top-left':
        newWidth += delta.dx;  // Dragging right increases width
        newHeight -= delta.dy; // Dragging up increases height
        break;
      case 'top-right':
        newWidth -= delta.dx;  // Dragging left increases width
        newHeight -= delta.dy; // Dragging up increases height
        break;
      case 'bottom-left':
        newWidth += delta.dx;  // Dragging right increases width
        newHeight += delta.dy; // Dragging down increases height
        break;
      case 'bottom-right':
        newWidth -= delta.dx;  // Dragging left increases width
        newHeight += delta.dy; // Dragging down increases height
        break;
      case 'top':
        newHeight -= delta.dy; // Dragging up increases height
        break;
      case 'bottom':
        newHeight += delta.dy; // Dragging down increases height
        break;
      case 'left':
        newWidth += delta.dx;  // Dragging right increases width
        break;
      case 'right':
        newWidth -= delta.dx;  // Dragging left increases width
        break;
    }

    // Send an event through the listener instead of using a callback.
    final resizeEvent = {
      "event": "onResize",
      "id": widget.widgetId,
      "data": {
        "width": newWidth.clamp(50.0, double.infinity),
        "height": newHeight.clamp(50.0, double.infinity),
      },
    };
    widget.listener?.onClicked(jsonEncode(resizeEvent));
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _dragGlobalPosition = null;
      _initialWidth = null;
      _initialHeight = null;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
        clipBehavior: Clip.none,
        children: [
          // Selection border
          Container(
            width: widget.width + 4,
            height: widget.height + 4,
            decoration: BoxDecoration(
              color: Colors.yellow.withOpacity(0.2), // debug background
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Main widget
          Positioned(
            left: 2,
            top: 2,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: widget.child,
            ),
          ),
          // Dimension overlay is shown during resize
          if (_dragGlobalPosition != null)
            Positioned(
              top: -30,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${widget.width.toInt()} × ${widget.height.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Corner handles (8x8, red, above edge handles)
          Positioned(
            left: -4,
            top: -4,
            child: _ResizeHandle(
              size: 8,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              color: Colors.grey.withOpacity(0.85),
              onPanStart: _onDragStart,
              onPanUpdate: (details) => _onDragUpdate(details, 'top-left'),
              onPanEnd: _onDragEnd,
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: _ResizeHandle(
              size: 8,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              color: Colors.grey.withOpacity(0.85),
              onPanStart: _onDragStart,
              onPanUpdate: (details) => _onDragUpdate(details, 'top-right'),
              onPanEnd: _onDragEnd,
            ),
          ),
          Positioned(
            left: -4,
            bottom: -4,
            child: _ResizeHandle(
              size: 8,
              cursor: SystemMouseCursors.resizeUpRightDownLeft,
              color: Colors.grey.withOpacity(0.85),
              onPanStart: _onDragStart,
              onPanUpdate: (details) => _onDragUpdate(details, 'bottom-left'),
              onPanEnd: _onDragEnd,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: _ResizeHandle(
              size: 8,
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              color: Colors.grey.withOpacity(0.85),
              onPanStart: _onDragStart,
              onPanUpdate:
                  (details) => _onDragUpdate(details, 'bottom-right'),
              onPanEnd: _onDragEnd,
            ),
          ),
          // Invisible edge handles for UX (transparent, but interactive)
          Positioned(
            left: (widget.width / 2) - 12,
            top: 0,
            child: _EdgeResizeHandle(
              width: 24,
              height: 8,
              cursor: SystemMouseCursors.resizeUpDown,
              onPanStart: _onDragStart,
              onPanUpdate: (details) => _onDragUpdate(details, 'top'),
              onPanEnd: _onDragEnd,
            ),
          ),
          Positioned(
            left: (widget.width / 2) - 12,
            bottom: 0,
            child: _EdgeResizeHandle(
              width: 24,
              height: 8,
              cursor: SystemMouseCursors.resizeUpDown,
              onPanStart: _onDragStart,
              onPanUpdate: (details) => _onDragUpdate(details, 'bottom'),
              onPanEnd: _onDragEnd,
            ),
          ),
          Positioned(
            left: 0,
            top: (widget.height / 2) - 12,
            child: _EdgeResizeHandle(
              width: 8,
              height: 24,
              cursor: SystemMouseCursors.resizeLeftRight,
              onPanStart: _onDragStart,
              onPanUpdate: (details) => _onDragUpdate(details, 'left'),
              onPanEnd: _onDragEnd,
            ),
          ),
          Positioned(
            right: 0,
            top: (widget.height / 2) - 12,
            child: _EdgeResizeHandle(
              width: 8,
              height: 24,
              cursor: SystemMouseCursors.resizeLeftRight,
              onPanStart: _onDragStart,
              onPanUpdate: (details) => _onDragUpdate(details, 'right'),
              onPanEnd: _onDragEnd,
            ),
          ),
        ],
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

class _ResizeHandle extends StatelessWidget {
  final double size;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final SystemMouseCursor cursor;
  final Color color;

  const _ResizeHandle({
    required this.size,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.cursor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: MouseRegion(
        cursor: cursor,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EdgeResizeHandle extends StatelessWidget {
  final double width;
  final double height;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final SystemMouseCursor cursor;

  const _EdgeResizeHandle({
    required this.width,
    required this.height,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.cursor,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.0), width: 0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
