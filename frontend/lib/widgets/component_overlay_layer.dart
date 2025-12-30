import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../models/component_model.dart';
import '../utilities/component_overlay_manager.dart';

/// An invisible overlay layer that sits on top of the canvas components
/// and handles all interaction (dragging, resizing, selection) without
/// interfering with the visual rendering of components below.
class ComponentOverlayLayer extends StatelessWidget {
  final Size canvasSize;
  
  const ComponentOverlayLayer({
    super.key,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    final canvasController = Get.find<CanvasController>();

    return Obx(() {
      return Stack(
        children: [
          // Create overlay widgets for each component
          ...canvasController.components.map((component) {
            return KeyedSubtree(
              key: ValueKey('overlay_${component.id}'),
              child: _buildComponentOverlay(component, canvasController),
            );
          }),
        ],
      );
    });
  }

  /// Build an invisible overlay widget for a single component
  Widget _buildComponentOverlay(
    ComponentModel component,
    CanvasController controller,
  ) {
    return ComponentOverlayManager.buildComponentOverlay(
      component: component,
      controller: controller,
      canvasSize: canvasSize,
    );
  }


}

