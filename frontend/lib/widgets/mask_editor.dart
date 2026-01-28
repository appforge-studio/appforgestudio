import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MaskEditor extends StatefulWidget {
  final String imageUrl;
  final double imageWidth;
  final double imageHeight;
  final Function(ui.Image mask) onMaskChanged;

  const MaskEditor({
    super.key,
    required this.imageUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.onMaskChanged,
  });

  @override
  State<MaskEditor> createState() => _MaskEditorState();
}

class _MaskEditorState extends State<MaskEditor> {
  final List<Offset?> _points = [];
  double _strokeWidth = 20.0;
  final GlobalKey _paintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: widget.imageWidth / widget.imageHeight,
              child: Container(
                key: _paintKey,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(widget.imageUrl, fit: BoxFit.cover),
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          final RenderBox renderBox =
                              _paintKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          _points.add(
                            renderBox.globalToLocal(details.globalPosition),
                          );
                        });
                        _updateMask();
                      },
                      onPanEnd: (details) {
                        _points.add(null);
                      },
                      child: CustomPaint(
                        painter: MaskPainter(
                          points: _points,
                          strokeWidth: _strokeWidth,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Brush Size:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Expanded(
              child: Slider(
                value: _strokeWidth,
                min: 5.0,
                max: 50.0,
                onChanged: (val) => setState(() => _strokeWidth = val),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white70),
              onPressed: () {
                setState(() {
                  if (_points.isNotEmpty) {
                    // Remove last stroke (from null back to previous null or start)
                    while (_points.isNotEmpty && _points.last == null) {
                      _points.removeLast();
                    }
                    while (_points.isNotEmpty && _points.last != null) {
                      _points.removeLast();
                    }
                  }
                });
                _updateMask();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white70),
              onPressed: () {
                setState(() => _points.clear());
                _updateMask();
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateMask() async {
    // Generate ui.Image from points
    // This is a simplified version, in a real app you'd want to render this to a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
      }
    }

    // Capture size of the widget
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    widget.onMaskChanged(img);
  }
}

class MaskPainter extends CustomPainter {
  final List<Offset?> points;
  final double strokeWidth;

  MaskPainter({required this.points, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
