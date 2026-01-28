import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../components/component_factory.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/sidebar_controller.dart';
import '../utilities/pallet.dart';
import 'layers_tree.dart';
import 'search_box.dart';
import 'agentic_edits_panel.dart';
import 'vector_editor/vector_editor_panel.dart';

const double controlWidth = 280;

class ComponentPanel extends StatelessWidget {
  const ComponentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarController = Get.find<SidebarController>();
    final canvasController = Get.find<CanvasController>();

    return SizedBox(
      width: controlWidth,
      child: Obx(() {
        if (canvasController.isEditingComponent) {
            return const VectorEditorPanel();
        }

        return Column(
        children: [
          // Logo row
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 10),
              // You can add logo images here if available
              // Image.asset("assets/logo_square.png", height: 30),
              // const SizedBox(width: 5),
              // Image.asset("assets/logo.png", height: 40),
              Text(
                'AppForge',
                style: TextStyle(
                  color: Pallet.font1,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 10),
                Column(
                  children: [
                    const SizedBox(height: 30),
                    Obx(() => _iconButton(
                      icon: FontAwesomeIcons.mobile,
                      selected: sidebarController.selectedPage == 0,
                      onTap: () => sidebarController.setSelectedPage(0),
                    )),
                    const SizedBox(height: 10),
                    Obx(() => _iconButton(
                      icon: FontAwesomeIcons.layerGroup,
                      selected: sidebarController.selectedPage == 1,
                      onTap: () => sidebarController.setSelectedPage(1),
                    )),
                    const SizedBox(height: 10),
                    Obx(() => _iconButton(
                      icon: FontAwesomeIcons.server,
                      selected: sidebarController.selectedPage == 2,
                      onTap: () => sidebarController.setSelectedPage(2),
                    )),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Pallet.inside1,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Obx(() => _buildContent(
                      selectedPage: sidebarController.selectedPage,
                      dividerPosition: sidebarController.dividerPosition,
                      dividerController: sidebarController,
                    )),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
     }),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FaIcon(icon, color: Pallet.inside3, size: 22),
      ),
    );
  }

  Widget _buildContent({
    required int selectedPage,
    required double dividerPosition,
    required SidebarController dividerController,
  }) {
    if (selectedPage == 2) {
      // Data/Code page - placeholder for now
      return const Center(
        child: Text(
          'Data/Code Editor',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final paneHeight = constraints.maxHeight;
        final topFlex = (dividerPosition * 100).clamp(20, 80).toInt();
        final bottomFlex = 100 - topFlex;
        
        return Column(
          children: [
            Flexible(
              flex: topFlex,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPage == 0 ? 'Components' : 'Layers',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: selectedPage == 0
                          ? _buildComponentsList()
                          : const LayersTree(),
                    ),
                  ],
                ),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  final dy = details.primaryDelta!;
                  final deltaRatio = dy / paneHeight;
                  final newPos = (dividerPosition + deltaRatio).clamp(0.2, 0.8);
                  dividerController.setDividerPosition(newPos);
                },
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Pallet.divider),
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              flex: bottomFlex,
              child: const AgenticEditsPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComponentsList() {
    return ListView(
      children: [
        const SearchBox(),
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
    );
  }

  Widget _componentTile(ComponentType type, {bool isDragging = false}) {
    // Determine icon based on type
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
      width: controlWidth,
      height: 40,
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey.withOpacity(0.5) : null,
        border: Border(bottom: BorderSide(color: Pallet.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          Icon(iconData, color: Pallet.font2, size: 13),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
