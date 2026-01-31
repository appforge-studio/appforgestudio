import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../models/alignment_guide_model.dart';
import '../models/alignment_guide_model.dart'
    as model; // Prefix to avoid conflict if needed

class AlignmentGuidesLayer extends StatelessWidget {
  final Size canvasSize;

  const AlignmentGuidesLayer({super.key, required this.canvasSize});

  @override
  Widget build(BuildContext context) {
    final canvasController = Get.find<CanvasController>();

    return Obx(() {
      final guides = canvasController.activeGuides;
      if (guides.isEmpty) return const SizedBox.shrink();

      return Stack(
        children: guides.map((guide) => _buildGuide(guide)).toList(),
      );
    });
  }

  Widget _buildGuide(AlignmentGuide guide) {
    // Styling
    final color = guide.isCenter ? Colors.red : Colors.orangeAccent;
    final strokeWidth = guide.isCenter ? 1.5 : 1.0;

    if (guide.axis == model.Axis.vertical) {
      // Vertical line (x position)
      return Positioned(
        left: guide.position,
        top: 0,
        bottom: 0,
        child: Container(width: strokeWidth, color: color),
      );
    } else {
      // Horizontal line (y position)
      return Positioned(
        left: 0,
        right: 0,
        top: guide.position,
        child: Container(height: strokeWidth, color: color),
      );
    }
  }
}
