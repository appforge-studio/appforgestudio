import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../providers/smart_guides.dart';

class SmartGuidesOverlay extends StatelessWidget {
  final Size canvasSize;
  
  const SmartGuidesOverlay({
    super.key,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SmartGuidesController>(
      builder: (controller) {
        final guides = controller.guides;
    
    if (guides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: guides.map((guide) => _SmartGuideLine(
        guide: guide,
        canvasSize: canvasSize,
      )).toList(),
    );
      },
    );
  }
}

class _SmartGuideLine extends StatelessWidget {
  final SmartGuide guide;
  final Size canvasSize;

  const _SmartGuideLine({
    required this.guide,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (guide.type) {
      case GuideType.vertical:
        return _VerticalGuide(guide: guide, canvasSize: canvasSize);
      case GuideType.horizontal:
        return _HorizontalGuide(guide: guide, canvasSize: canvasSize);
      case GuideType.centerVertical:
        return _CenterVerticalGuide(guide: guide, canvasSize: canvasSize);
      case GuideType.centerHorizontal:
        return _CenterHorizontalGuide(guide: guide, canvasSize: canvasSize);
    }
  }
}

class _VerticalGuide extends StatelessWidget {
  final SmartGuide guide;
  final Size canvasSize;

  const _VerticalGuide({
    required this.guide,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: guide.position - 1, // Center the 2px line
      top: 0,
      child: Container(
        width: 2,
        height: canvasSize.height,
        decoration: BoxDecoration(
          color: guide.color,
          boxShadow: [
            BoxShadow(
              color: guide.color.withOpacity(0.3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalGuide extends StatelessWidget {
  final SmartGuide guide;
  final Size canvasSize;

  const _HorizontalGuide({
    required this.guide,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: guide.position - 1, // Center the 2px line
      child: Container(
        width: canvasSize.width,
        height: 2,
        decoration: BoxDecoration(
          color: guide.color,
          boxShadow: [
            BoxShadow(
              color: guide.color.withOpacity(0.3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterVerticalGuide extends StatelessWidget {
  final SmartGuide guide;
  final Size canvasSize;

  const _CenterVerticalGuide({
    required this.guide,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: guide.position - 1,
      top: 0,
      child: Container(
        width: 2,
        height: canvasSize.height,
        decoration: BoxDecoration(
          color: guide.color,
          boxShadow: [
            BoxShadow(
              color: guide.color.withOpacity(0.3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _CenterIndicatorPainter(color: guide.color),
        ),
      ),
    );
  }
}

class _CenterHorizontalGuide extends StatelessWidget {
  final SmartGuide guide;
  final Size canvasSize;

  const _CenterHorizontalGuide({
    required this.guide,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: guide.position - 1,
      child: Container(
        width: canvasSize.width,
        height: 2,
        decoration: BoxDecoration(
          color: guide.color,
          boxShadow: [
            BoxShadow(
              color: guide.color.withOpacity(0.3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _CenterIndicatorPainter(color: guide.color),
        ),
      ),
    );
  }
}

class _CenterIndicatorPainter extends CustomPainter {
  final Color color;

  _CenterIndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw center indicator (small circle or diamond)
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 4.0;
    
    // Draw a diamond shape
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.lineTo(center.dx + radius, center.dy);
    path.lineTo(center.dx, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 