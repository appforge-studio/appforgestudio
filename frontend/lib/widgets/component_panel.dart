import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/component_factory.dart';
import '../controllers/canvas_controller.dart';
import '../utilities/pallet.dart';

class ComponentPanel extends StatelessWidget {
  const ComponentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, // Matched closer to controlWidth
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Header or Logo area if needed, for now just spacing or title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              "Components",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Pallet.font1,
              ),
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 10),
                for (var type in ComponentType.values)
                  Draggable<ComponentType>(
                    data: type,
                    feedback: _componentTile(type, isDragging: true),
                    childWhenDragging: _componentTile(type, isDragging: true),
                    child: _componentTile(type),
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
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _componentTile(ComponentType type, {bool isDragging = false}) {
    // Determine icon based on type (using standard icons for now as placeholders)
    IconData iconData;
    switch (type) {
      case ComponentType.container:
        iconData = Icons.check_box_outline_blank;
        break;
      case ComponentType.text:
        iconData = Icons.text_fields;
        break;
      case ComponentType.image:
        iconData = Icons.image;
        break;
      case ComponentType.icon:
        iconData = Icons.star;
        break;
    }

    final label = type.name[0].toUpperCase() + type.name.substring(1);

    return Container(
      width: 250,
      height: 40,
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey.withOpacity(0.5) : null,
        border: Border(bottom: BorderSide(color: Pallet.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(iconData, color: Pallet.font2, size: 16),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, color: Pallet.font1)),
        ],
      ),
    );
  }
}
