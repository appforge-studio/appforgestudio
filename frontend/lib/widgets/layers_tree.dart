import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../models/component_model.dart';
import '../components/component_factory.dart';
import '../utilities/pallet.dart';

class LayersTree extends StatelessWidget {
  const LayersTree({super.key});

  @override
  Widget build(BuildContext context) {
    final canvasController = Get.find<CanvasController>();
    
    return Obx(() {
      final components = canvasController.components;
      final selectedIds = canvasController.selectedComponentIds;
      
      if (components.isEmpty) {
        return Center(
          child: Text(
            'No components',
            style: TextStyle(
              color: Pallet.font3,
              fontSize: 12,
            ),
          ),
        );
      }
      
      return ListView.builder(
        itemCount: components.length,
        itemBuilder: (context, index) {
          final component = components[index];
          final isSelected = selectedIds.contains(component.id);
          
          return _LayerItem(
            component: component,
            isSelected: isSelected,
            onTap: () {
              canvasController.onComponentSelected(component);
            },
          );
        },
      );
    });
  }
}

class _LayerItem extends StatelessWidget {
  final ComponentModel component;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayerItem({
    required this.component,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get icon based on component type
    IconData iconData;
    switch (component.type) {
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

    final label = component.type.name[0].toUpperCase() +
        component.type.name.substring(1);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF221D43) : null,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF221D43).withOpacity(0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(iconData, color: Pallet.insideFont, size: 13),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Pallet.insideFont,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

