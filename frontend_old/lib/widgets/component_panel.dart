import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/enums.dart';
import '../controllers/canvas_controller.dart';

class ComponentPanel extends StatelessWidget {
  const ComponentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: const Text(
              'Components',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Component list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildComponentItem(
                    ComponentType.container,
                    'Container',
                    Icons.crop_square,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildComponentItem(
                    ComponentType.text,
                    'Text',
                    Icons.text_fields,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildComponentItem(
                    ComponentType.image,
                    'Image',
                    Icons.image,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentItem(
    ComponentType type,
    String label,
    IconData icon,
    Color color,
  ) {
    return Draggable<ComponentType>(
      data: type,
      feedback: _buildDragFeedback(label, icon, color),
      childWhenDragging: _buildComponentPreview(label, icon, color, isDragging: true),
      onDragStarted: () {
        final canvasController = Get.find<CanvasController>();
        canvasController.onDragStart(type);
      },
      onDragEnd: (details) {
        final canvasController = Get.find<CanvasController>();
        // Let the canvas handle the positioning through DragTarget
        // Only reset the dragging state here
        if (!details.wasAccepted) {
          canvasController.onDragEnd(Offset.zero, null);
        }
      },
      child: _buildComponentPreview(label, icon, color),
    );
  }

  Widget _buildComponentPreview(
    String label,
    IconData icon,
    Color color, {
    bool isDragging = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDragging ? Colors.grey[400]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: isDragging
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDragging ? Colors.grey[600] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragFeedback(String label, IconData icon, Color color) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}