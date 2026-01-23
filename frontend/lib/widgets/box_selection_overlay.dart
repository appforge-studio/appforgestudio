import 'package:flutter/material.dart';

/// A custom painter that draws a dashed border like Figma's selection box
class DashedBorderPainter extends CustomPainter {
  final Color borderColor;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    this.borderColor = const Color(0xFF18A0FB),
    this.strokeWidth = 1.5,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dashPattern = <double>[dashWidth, dashSpace];

    // Top edge
    _drawDashedLine(
      canvas,
      Offset(0, 0),
      Offset(size.width, 0),
      paint,
      dashPattern,
    );

    // Right edge
    _drawDashedLine(
      canvas,
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
      dashPattern,
    );

    // Bottom edge
    _drawDashedLine(
      canvas,
      Offset(size.width, size.height),
      Offset(0, size.height),
      paint,
      dashPattern,
    );

    // Left edge
    _drawDashedLine(
      canvas,
      Offset(0, size.height),
      Offset(0, 0),
      paint,
      dashPattern,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> dashPattern,
  ) {
    final path = Path();
    final distance = (end - start).distance;
    final direction = (end - start) / distance;

    double currentDistance = 0;
    bool draw = true;
    int dashIndex = 0;

    while (currentDistance < distance) {
      final dashLength = dashPattern[dashIndex % dashPattern.length];
      
      if (draw) {
        final dashEnd = start + direction * (currentDistance + dashLength).clamp(0.0, distance);
        path.moveTo(start.dx + direction.dx * currentDistance, start.dy + direction.dy * currentDistance);
        path.lineTo(dashEnd.dx, dashEnd.dy);
        canvas.drawPath(path, paint);
        path.reset();
      }
      
      currentDistance += dashLength;
      draw = !draw;
      dashIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}

/// Figma-style box selection overlay widget
class BoxSelectionOverlay extends StatelessWidget {
  final Rect rect;

  const BoxSelectionOverlay({
    super.key,
    required this.rect,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Stack(
        children: [
          // Semi-transparent fill
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF18A0FB).withOpacity(0.1),
            ),
          ),
          // Dashed border
          CustomPaint(
            painter: DashedBorderPainter(
              borderColor: const Color(0xFF18A0FB),
              strokeWidth: 1.5,
              dashWidth: 4.0,
              dashSpace: 4.0,
            ),
            child: SizedBox(
              width: rect.width,
              height: rect.height,
            ),
          ),
        ],
      ),
    );
  }
}

