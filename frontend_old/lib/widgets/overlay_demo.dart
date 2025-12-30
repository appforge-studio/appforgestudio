import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../models/enums.dart';
import '../utilities/component_factory.dart';
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildDraggableComponent(ComponentType.container, 'Container'),
                      _buildDraggableComponent(ComponentType.text, 'Text'),
                      _buildDraggableComponent(ComponentType.image, 'Image'),
                    ],
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
          const Expanded(
            child: DesignCanvas(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableComponent(ComponentType type, String label) {
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
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
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
              Icon(_getIconForType(type), size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(ComponentType type) {
    switch (type) {
      case ComponentType.container:
        return Icons.crop_square;
      case ComponentType.text:
        return Icons.text_fields;
      case ComponentType.image:
        return Icons.image;
    }
  }

  void _addSampleComponents() {
    final controller = Get.find<CanvasController>();
    
    // Add a few sample components to demonstrate the overlay
    final containerComponent = ComponentFactory.createComponent(
      ComponentType.container,
      50,
      50,
    );
    
    final textComponent = ComponentFactory.createComponent(
      ComponentType.text,
      200,
      100,
    );
    
    // Customize the text component to make it more visible
    final textProperties = textComponent.properties
        .updateProperty('content', 'Hello World!')
        .updateProperty('fontSize', 18.0);
    final customizedTextComponent = textComponent.copyWith(properties: textProperties);
    
    final imageComponent = ComponentFactory.createComponent(
      ComponentType.image,
      100,
      200,
    );
    
    controller.addComponent(containerComponent);
    controller.addComponent(customizedTextComponent);
    controller.addComponent(imageComponent);
    
    // Select the text component to demonstrate property editor
    controller.onComponentSelected(customizedTextComponent);
  }

  void _clearCanvas() {
    final controller = Get.find<CanvasController>();
    controller.clearCanvas();
  }
}