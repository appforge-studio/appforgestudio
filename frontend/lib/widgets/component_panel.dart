import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/component_factory.dart';
import '../controllers/canvas_controller.dart';

class ComponentPanel extends StatelessWidget {
  const ComponentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(right: BorderSide(color: Colors.grey[300]!, width: 1)),
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
              child: SingleChildScrollView(
                child: Column(
                  children: ComponentType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildComponentItem(type),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentItem(ComponentType type) {
    // Capitalize first letter for label
    final label = type.name[0].toUpperCase() + type.name.substring(1);

    return Draggable<ComponentType>(
      data: type,
      feedback: _buildDragFeedback(label),
      childWhenDragging: _buildComponentPreview(label, isDragging: true),
      onDragStarted: () {
        final canvasController = Get.find<CanvasController>();
        canvasController.onDragStart(type);
      },
      onDragEnd: (details) {
        final canvasController = Get.find<CanvasController>();
        if (!details.wasAccepted) {
          canvasController.onDragEnd(Offset.zero, null);
        }
      },
      child: _buildComponentPreview(label),
    );
  }

  Widget _buildComponentPreview(String label, {bool isDragging = false}) {
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
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.widgets, color: Colors.grey, size: 18),
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

  Widget _buildDragFeedback(String label) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.widgets, color: Colors.grey, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
