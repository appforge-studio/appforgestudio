import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../components/component_factory.dart';
import 'design_canvas.dart';

/// Demo widget to showcase the overlay layer functionality
class OverlayDemo extends StatelessWidget {
  const OverlayDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Overlay Layer Demo'),
        backgroundColor: Colors.blue[50],
      ),
      body: Row(
        children: [
          // Component palette
          Container(
            width: 200,
            color: Colors.grey[100],
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Components',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: ComponentType.values.map((type) {
                      return _buildDraggableComponent(type);
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _addSampleComponents,
                        child: const Text('Add Sample Components'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _clearCanvas,
                        child: const Text('Clear Canvas'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Canvas area
          const Expanded(child: DesignCanvas()),
        ],
      ),
    );
  }

  Widget _buildDraggableComponent(ComponentType type) {
    // Capitalize first letter for label
    final label = type.name[0].toUpperCase() + type.name.substring(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Draggable<ComponentType>(
        data: type,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        childWhenDragging: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: Text(label, style: TextStyle(color: Colors.grey[600])),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.widgets, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  void _addSampleComponents() {
    final controller = Get.find<CanvasController>();
    double startX = 50;
    double startY = 50;
    double offset = 100;

    // Add one of each component type
    for (var i = 0; i < ComponentType.values.length; i++) {
      final type = ComponentType.values[i];
      final component = ComponentFactory.createComponent(
        type,
        startX + (i * 20),
        startY + (i * offset),
      );
      controller.addComponent(component);
    }
  }

  void _clearCanvas() {
    final controller = Get.find<CanvasController>();
    controller.clearCanvas();
  }
}
