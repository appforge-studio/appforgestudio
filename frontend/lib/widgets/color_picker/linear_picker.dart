import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinearColorPicker extends StatefulWidget {
  final List<Color> colors;
  final List<double> stops;
  final ValueChanged<List<Color>>? onColorsChanged;
  final ValueChanged<List<double>>? onStopsChanged;
  final ValueChanged<int>? onSelectionChanged;
  final int selectedIndex;

  const LinearColorPicker({
    super.key,
    required this.colors,
    required this.stops,
    this.onColorsChanged,
    this.onStopsChanged,
    this.onSelectionChanged,
    required this.selectedIndex,
  });

  @override
  State<LinearColorPicker> createState() => _LinearColorPickerState();
}

class _LinearColorPickerState extends State<LinearColorPicker> {
  void _updateStop(int index, double value) {
    if (widget.onStopsChanged != null) {
      // Clamp to neighbors to prevent crossing and index swapping
      double min = index > 0 ? widget.stops[index - 1] + 0.005 : 0.0;
      double max = index < widget.stops.length - 1
          ? widget.stops[index + 1] - 0.005
          : 1.0;

      final newValue = value.clamp(min, max);

      final List<double> newStops = List.from(widget.stops);
      newStops[index] = newValue;

      widget.onStopsChanged?.call(newStops);
      // No need to update colors or selection index since order is preserved
    }
  }

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDelete() {
    final index = widget.selectedIndex;
    if (index == -1) return;
    // Prevent deleting start/end stops (must keep at least 2)
    if (index == 0 || index == widget.stops.length - 1) return;
    if (widget.stops.length <= 2) return;

    final newStops = List<double>.from(widget.stops);
    final newColors = List<Color>.from(widget.colors);

    newStops.removeAt(index);
    newColors.removeAt(index);

    widget.onColorsChanged?.call(newColors);
    widget.onStopsChanged?.call(newStops);
    widget.onSelectionChanged?.call(-1);
  }

  // _updateAndSort is no longer needed for dragging

  void _addStop(double position) {
    final stops = List<double>.from(widget.stops);
    final colors = List<Color>.from(widget.colors);

    Color newColor = _calculateColorAt(position, stops, colors);

    stops.add(position);
    colors.add(newColor);

    // Pass -1 as activeIndex since we are adding a new one, we'll handle selection manually
    List<_Stop> composite = [];
    for (int i = 0; i < stops.length; i++) {
      // Mark the NEW one (last added) as active
      composite.add(_Stop(stops[i], colors[i], i == stops.length - 1));
    }

    composite.sort((a, b) => a.pos.compareTo(b.pos));

    final newStops = composite.map((e) => e.pos).toList();
    final newColors = composite.map((e) => e.color).toList();

    int newIndex = 0;
    for (int i = 0; i < composite.length; i++) {
      if (composite[i].wasActive) {
        newIndex = i;
        break;
      }
    }

    widget.onColorsChanged!(newColors);
    widget.onStopsChanged!(newStops);
    widget.onSelectionChanged?.call(newIndex);
  }

  Color _calculateColorAt(
    double position,
    List<double> stops,
    List<Color> colors,
  ) {
    if (stops.isEmpty) return Colors.white;
    if (stops.length == 1) return colors[0];

    List<_Stop> sorted = [];
    for (int i = 0; i < stops.length; i++) {
      sorted.add(_Stop(stops[i], colors[i], false));
    }
    sorted.sort((a, b) => a.pos.compareTo(b.pos));

    if (position <= sorted.first.pos) return sorted.first.color;
    if (position >= sorted.last.pos) return sorted.last.color;

    for (int i = 0; i < sorted.length - 1; i++) {
      if (position >= sorted[i].pos && position <= sorted[i + 1].pos) {
        double t =
            (position - sorted[i].pos) / (sorted[i + 1].pos - sorted[i].pos);
        return Color.lerp(sorted[i].color, sorted[i + 1].color, t) ??
            Colors.white;
      }
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            _handleDelete();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double handleWidth = 20.0;
          const double trackPadding = handleWidth / 2;
          final double trackWidth = constraints.maxWidth - handleWidth;

          return GestureDetector(
            onTapUp: (details) {
              double localDx = details.localPosition.dx - trackPadding;
              double pos = (localDx / trackWidth).clamp(0.0, 1.0);
              // Only add if we clicked on the bar area (top part)
              if (details.localPosition.dy <= 30) {
                _addStop(pos);
              }
            },
            child: SizedBox(
              height: 45, // Total height including handles
              width: constraints.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Checkerboard Background
                  Positioned(
                    left: trackPadding,
                    right: trackPadding,
                    top: 10,
                    height: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(painter: CheckboardPainter()),
                    ),
                  ),
                  // The Gradient Bar
                  Positioned(
                    left: trackPadding,
                    right: trackPadding,
                    top: 10,
                    height: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        // border: Border.all(color: Pallet.divider),
                        gradient: LinearGradient(
                          colors: widget.colors,
                          stops: widget.stops,
                        ),
                      ),
                    ),
                  ),
                  // The Handles
                  ...List.generate(widget.stops.length, (index) {
                    final double stop = widget.stops[index];
                    final bool isSelected = index == widget.selectedIndex;

                    return Positioned(
                      key: ValueKey('handle-$index'),
                      left:
                          trackPadding +
                          stop * trackWidth -
                          10, // Center the handle (20px width)
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) =>
                            debugPrint('Handle $index Pan Start'),
                        onPanDown: (_) => debugPrint('Handle $index Pan Down'),
                        onPanUpdate: (details) {
                          debugPrint(
                            'Handle $index Pan Update: ${details.delta.dx}',
                          );
                          double delta = details.delta.dx / trackWidth;
                          _updateStop(index, stop + delta);
                        },
                        onTap: () {
                          debugPrint('Handle $index Tap');
                          _focusNode.requestFocus();
                          widget.onSelectionChanged?.call(index);
                        },
                        child: _buildHandle(widget.colors[index], isSelected),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle(Color color, bool isSelected) {
    return Container(
      width: 20,
      color: Colors.transparent, // Hit test target
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 9),
          // Triangle/Indicator on top?
          // Or just the circle style like the image (white circle with color inside)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stop {
  final double pos;
  final Color color;
  final bool wasActive;
  _Stop(this.pos, this.color, this.wasActive);
}

class CheckboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.grey.shade300;
    Paint white = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, white);

    double boxSize = 8;
    for (double y = 0; y < size.height; y += boxSize) {
      for (double x = 0; x < size.width; x += boxSize) {
        if (((x / boxSize).floor() + (y / boxSize).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, boxSize, boxSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
