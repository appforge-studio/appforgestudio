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

import 'screen_list_panel.dart';

const double controlWidth = 280;

class ComponentPanel extends StatelessWidget {
  const ComponentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarController = Get.find<SidebarController>();
    final canvasController = Get.find<CanvasController>();

    return SizedBox(
      width: controlWidth,
      child: Column(
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
                    Obx(() {
                      if (canvasController.isEditingComponent) {
                        // Vector Tools
                        return Column(
                          children: [
                            _iconButton(
                              icon: FontAwesomeIcons.arrowPointer,
                              selected: true, // TODO: Track active tool
                              onTap: () {},
                            ),
                            const SizedBox(height: 10),
                            _iconButton(
                              icon: FontAwesomeIcons.bezierCurve,
                              selected: false,
                              onTap: () {},
                            ),
                            const SizedBox(height: 10),
                            _iconButton(
                              icon: FontAwesomeIcons.pen,
                              selected: false,
                              onTap: () {},
                            ),
                            const SizedBox(height: 40),
                            _iconButton(
                              icon: Icons.check, // Done
                              selected: false,
                              onTap: () =>
                                  canvasController.setEditingComponent(null),
                              color: Colors.green,
                            ),
                          ],
                        );
                      } else {
                        // Standard Navigation
                        return Column(
                          children: [
                            _iconButton(
                              icon: FontAwesomeIcons.mobile,
                              selected:
                                  sidebarController.selectedPage ==
                                  SidebarController.PAGE_SCREENS,
                              onTap: () => sidebarController.setSelectedPage(
                                SidebarController.PAGE_SCREENS,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _iconButton(
                              icon: FontAwesomeIcons
                                  .shapes, // Changed from mobile to shapes for components
                              selected:
                                  sidebarController.selectedPage ==
                                  SidebarController.PAGE_COMPONENTS,
                              onTap: () => sidebarController.setSelectedPage(
                                SidebarController.PAGE_COMPONENTS,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _iconButton(
                              icon: FontAwesomeIcons.layerGroup,
                              selected:
                                  sidebarController.selectedPage ==
                                  SidebarController.PAGE_LAYERS,
                              onTap: () => sidebarController.setSelectedPage(
                                SidebarController.PAGE_LAYERS,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _iconButton(
                              icon: FontAwesomeIcons.server,
                              selected:
                                  sidebarController.selectedPage ==
                                  SidebarController.PAGE_DATA,
                              onTap: () => sidebarController.setSelectedPage(
                                SidebarController.PAGE_DATA,
                              ),
                            ),
                          ],
                        );
                      }
                    }),
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
                    child: Obx(
                      () => _buildContent(
                        selectedPage: sidebarController.selectedPage,
                        dividerPosition: sidebarController.dividerPosition,
                        dividerController: sidebarController,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
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
        child: FaIcon(icon, color: color ?? Pallet.inside3, size: 22),
      ),
    );
  }

  Widget _buildContent({
    required int selectedPage,
    required double dividerPosition,
    required SidebarController dividerController,
  }) {
    if (selectedPage == SidebarController.PAGE_DATA) {
      // Data/Code page - placeholder for now
      return const Center(
        child: Text(
          'Data/Code Editor',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    // Screens page -> Full height, no AI panel
    if (selectedPage == SidebarController.PAGE_SCREENS) {
      return _buildPanelContent(selectedPage);
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
                    if (selectedPage != SidebarController.PAGE_SCREENS)
                      Text(
                        selectedPage == SidebarController.PAGE_COMPONENTS
                            ? 'Components'
                            : 'Layers',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    if (selectedPage != SidebarController.PAGE_SCREENS)
                      const SizedBox(height: 10),
                    Expanded(child: _buildPanelContent(selectedPage)),
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
                    border: Border(top: BorderSide(color: Pallet.divider)),
                  ),
                ),
              ),
            ),
            Flexible(flex: bottomFlex, child: const AgenticEditsPanel()),
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

  Widget _buildPanelContent(int selectedPage) {
    switch (selectedPage) {
      case SidebarController.PAGE_SCREENS:
        return const ScreenListPanel();
      case SidebarController.PAGE_COMPONENTS:
        return _buildComponentsList();
      case SidebarController.PAGE_LAYERS:
        return const LayersTree();
      default:
        return const SizedBox();
    }
  }
}
