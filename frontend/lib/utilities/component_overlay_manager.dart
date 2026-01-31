import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../models/component_model.dart';
import 'component_dimensions.dart';
import '../components/component_factory.dart';

/// Unified manager for all component overlay interactions
/// Handles dragging, resizing, selection, and cursor management
class ComponentOverlayManager {
  // Constants
  static const double handleSize = 8;
  static const double edgeThreshold = 8.0;
  static const Color handleColor = Colors.blue;
  static const Color selectionColor = Colors.blue;
  static const Color overlayColor =
      Colors.deepPurple; // Light purple for overlay visualization

  /// Get the appropriate cursor for a resize handle or interaction type
  static SystemMouseCursor getCursor(String type) {
    switch (type) {
      // Resize cursors
      case 'nw':
      case 'se':
        return SystemMouseCursors.resizeUpLeftDownRight;
      case 'ne':
      case 'sw':
        return SystemMouseCursors.resizeUpRightDownLeft;
      case 'n':
      case 's':
        return SystemMouseCursors.resizeUpDown;
      case 'e':
      case 'w':
        return SystemMouseCursors.resizeLeftRight;
      // Drag cursors
      case 'grab':
        return SystemMouseCursors.grab;
      case 'grabbing':
        return SystemMouseCursors.grabbing;
      case 'copy':
        return SystemMouseCursors.copy;
      default:
        return SystemMouseCursors.basic;
    }
  }

  static Widget buildComponentOverlay({
    required ComponentModel component,
    required CanvasController controller,
    required Size canvasSize,
  }) {
    // Base dimensions
    final baseWidth = ComponentDimensions.getWidth(component);
    final baseHeight = ComponentDimensions.getHeight(component);

    return Positioned(
      left: component.x,
      top: component.y,
      child: _ComponentOverlay(
        component: component,
        controller: controller,
        canvasSize: canvasSize,
        baseWidth: baseWidth ?? component.detectedSize?.width ?? 0.0,
        baseHeight: baseHeight ?? component.detectedSize?.height ?? 0.0,
      ),
    );
  }

  /// Build main interaction area for dragging and selection
  static Widget _buildMainInteractionArea({
    required ComponentModel component,
    required CanvasController controller,
    required Size canvasSize,
    required double width,
    required double height,
    required bool isDragging,
    required bool isResizing,
  }) {
    return Positioned(
      left: 0,
      top: 0,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: _getMainCursor(
          component: component,
          controller: controller,
          isDragging: isDragging,
          isResizing: isResizing,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior
              .opaque, // Capture events for component interactions
          onTap: () {
            // Don't select component if box selection is active
            if (!isDragging && !isResizing && !controller.isBoxSelecting) {
              controller.onComponentSelected(component);
            }
          },
          onDoubleTap: () {
            if (component.type == ComponentType.icon) {
              controller.setEditingComponent(component.id);
            }
          },
          onSecondaryTapDown: (details) {
            _showContextMenu(details, component, controller);
          },
          onPanStart: (details) {
            // Don't start component drag if box selection is active
            if (!isResizing && !controller.isBoxSelecting) {
              // If component is already selected, don't re-select (prevents clearing other selections)
              if (!controller.selectedComponentIds.contains(component.id)) {
                controller.onComponentSelected(component);
              }
              _handleDragStart(controller, component.id, details);
            }
          },
          onPanUpdate: (details) {
            if (controller.isDraggingComponent &&
                controller.draggingComponentId == component.id) {
              _handleDragUpdate(
                controller: controller,
                component: component,
                details: details,
                canvasSize: canvasSize,
                width: width,
                height: height,
              );
            }
          },
          onPanEnd: (details) {
            if (controller.isDraggingComponent &&
                controller.draggingComponentId == component.id) {
              _handleDragEnd(controller, component.id, details);
            }
          },
          child: Container(
            width: width,
            height: height,
            color: Colors.transparent, // Invisible but captures gestures
          ),
        ),
      ),
    );
  }

  /// Build selection indicator border with resize functionality
  static Widget _buildSelectionIndicator({
    required bool isDragging,
    required bool isResizing,
    required ComponentModel component,
    required CanvasController controller,
    required double width,
    required double height,
    required bool isSelected,
  }) {
    // Determine border color/style based on selection state
    final borderColor = isSelected
        ? selectionColor
        : selectionColor.withValues(alpha: 0.5);
    final borderWidth = isDragging || isResizing ? 3.0 : 2.0;

    return Positioned.fill(
      child: Stack(
        children: [
          // Visual border (non-interactive)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDragging || isResizing
                      ? selectionColor.withValues(alpha: 0.8)
                      : borderColor,
                  width: borderWidth,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          // Interactive border zones for resizing (ONLY when selected)
          if (isSelected && component.resizable && !isDragging)
            ..._buildBorderResizeZones(
              component: component,
              controller: controller,
              width: width,
              height: height,
            ),
        ],
      ),
    );
  }

  /// Build visible resize handles
  static List<Widget> _buildResizeHandles({
    required ComponentModel component,
    required CanvasController controller,
    required double width,
    required double height,
  }) {
    return [
      // Corner handles (dots)
      _buildResizeHandle(
        'nw',
        -handleSize / 2,
        -handleSize / 2,
        controller,
        component.id,
        const ValueKey('handle_nw'),
      ),
      _buildResizeHandle(
        'ne',
        width - handleSize / 2,
        -handleSize / 2,
        controller,
        component.id,
        const ValueKey('handle_ne'),
      ),
      _buildResizeHandle(
        'sw',
        -handleSize / 2,
        height - handleSize / 2,
        controller,
        component.id,
        const ValueKey('handle_sw'),
      ),
      _buildResizeHandle(
        'se',
        width - handleSize / 2,
        height - handleSize / 2,
        controller,
        component.id,
        const ValueKey('handle_se'),
      ),
    ];
  }

  /// Build invisible edge detection zones
  static List<Widget> _buildEdgeDetectionZones({
    required ComponentModel component,
    required CanvasController controller,
    required double width,
    required double height,
  }) {
    return [
      // Corner zones only
      _buildEdgeZone(
        'nw',
        0,
        0,
        edgeThreshold,
        edgeThreshold,
        component,
        controller,
      ),
      _buildEdgeZone(
        'ne',
        width - edgeThreshold,
        0,
        edgeThreshold,
        edgeThreshold,
        component,
        controller,
      ),
      _buildEdgeZone(
        'sw',
        0,
        height - edgeThreshold,
        edgeThreshold,
        edgeThreshold,
        component,
        controller,
      ),
      _buildEdgeZone(
        'se',
        width - edgeThreshold,
        height - edgeThreshold,
        edgeThreshold,
        edgeThreshold,
        component,
        controller,
      ),
    ];
  }

  /// Build a single resize handle (corner dot)
  static Widget _buildResizeHandle(
    String handle,
    double left,
    double top,
    CanvasController controller,
    String componentId,
    Key key,
  ) {
    return Positioned(
      key: key,
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) =>
            _handleResizeStart(controller, componentId, handle),
        onPanUpdate: (details) =>
            _handleResizeUpdate(controller, componentId, details),
        onPanEnd: (details) => _handleResizeEnd(controller, componentId),
        onPanCancel: () {
          debugPrint('Resize gesture canceled for $handle');
          _handleResizeEnd(controller, componentId);
        },
        child: MouseRegion(
          cursor: getCursor(handle),
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 1.0),
              borderRadius: BorderRadius.circular(handleSize / 2),
            ),
          ),
        ),
      ),
    );
  }

  /// Build an invisible edge detection zone
  static Widget _buildEdgeZone(
    String handle,
    double left,
    double top,
    double zoneWidth,
    double zoneHeight,
    ComponentModel component,
    CanvasController controller,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: MouseRegion(
        cursor: getCursor(handle),
        child: GestureDetector(
          onPanStart: (details) {
            controller.onComponentSelected(component);
            _handleResizeStart(controller, component.id, handle);
          },
          onPanUpdate: (details) =>
              _handleResizeUpdate(controller, component.id, details),
          onPanEnd: (details) => _handleResizeEnd(controller, component.id),
          child: Container(
            width: zoneWidth,
            height: zoneHeight,
            color: Colors.transparent, // Invisible but interactive
          ),
        ),
      ),
    );
  }

  /// Get cursor for main interaction area
  static SystemMouseCursor _getMainCursor({
    required ComponentModel component,
    required CanvasController controller,
    required bool isDragging,
    required bool isResizing,
  }) {
    if (isDragging) {
      return getCursor('grabbing');
    } else if (isResizing) {
      return getCursor(controller.resizeHandle);
    } else {
      return getCursor('grab');
    }
  }

  static void _handleDragStart(
    CanvasController controller,
    String componentId,
    DragStartDetails details,
  ) {
    // Cancel box selection if component drag starts
    if (controller.isBoxSelecting) {
      controller.endBoxSelection();
    }

    // Start interaction for all selected components
    for (final id in controller.selectedComponentIds) {
      controller.startInteraction(id);
    }

    controller.setDragState(componentId, true);
  }

  static void _handleDragUpdate({
    required CanvasController controller,
    required ComponentModel component,
    required DragUpdateDetails details,
    required Size canvasSize,
    required double width,
    required double height,
  }) {
    // We only drive the movement via the "primary" component being dragged (the one receiving the gesture)
    // The controller matches relative movement for others.

    // Pass the raw delta to the controller, let it handle snapping and updating ALL selected components.
    controller.moveComponentWithSnapping(
      component.id,
      details.delta.dx,
      details.delta.dy,
    );
  }

  static void _handleDragEnd(
    CanvasController controller,
    String componentId,
    DragEndDetails details,
  ) {
    // Commit interaction for all selected components
    for (final id in controller.selectedComponentIds) {
      controller.commitInteraction(id);
    }
    controller.setDragState(componentId, false);
    controller.clearGuides(); // Clear guides on end
  }

  // Resize handlers
  static void _handleResizeStart(
    CanvasController controller,
    String componentId,
    String handle,
  ) {
    // Cancel box selection if resize starts
    if (controller.isBoxSelecting) {
      controller.endBoxSelection();
    }
    controller.startInteraction(componentId);
    controller.setResizeState(componentId, true, handle: handle);
  }

  static void _handleResizeUpdate(
    CanvasController controller,
    String componentId,
    details,
  ) {
    if (controller.isResizingComponent &&
        controller.resizingComponentId == componentId) {
      // Calculate delta
      final dx = details.delta.dx;
      final dy = details.delta.dy;

      // Use the new centralized method in controller
      controller.resizeComponentTransient(componentId, dx, dy);
    }
  }

  static void _handleResizeEnd(
    CanvasController controller,
    String componentId,
  ) {
    if (controller.isResizingComponent &&
        controller.resizingComponentId == componentId) {
      controller.commitInteraction(componentId);
      controller.setResizeState(componentId, false);
    }
  }

  /// Build interactive border zones for edge resizing
  static List<Widget> _buildBorderResizeZones({
    required ComponentModel component,
    required CanvasController controller,
    required double width,
    required double height,
  }) {
    const borderThickness = 6.0; // Thickness of the interactive border zone

    return [
      // Top border
      _buildBorderZone(
        'n',
        0,
        -borderThickness / 2,
        width,
        borderThickness,
        component,
        controller,
      ),
      // Bottom border
      _buildBorderZone(
        's',
        0,
        height - borderThickness / 2,
        width,
        borderThickness,
        component,
        controller,
      ),
      // Left border
      _buildBorderZone(
        'w',
        -borderThickness / 2,
        0,
        borderThickness,
        height,
        component,
        controller,
      ),
      // Right border
      _buildBorderZone(
        'e',
        width - borderThickness / 2,
        0,
        borderThickness,
        height,
        component,
        controller,
      ),
    ];
  }

  /// Build a single border zone for resizing
  static Widget _buildBorderZone(
    String handle,
    double left,
    double top,
    double width,
    double height,
    ComponentModel component,
    CanvasController controller,
  ) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onPanStart: (details) =>
            _handleResizeStart(controller, component.id, handle),
        onPanUpdate: (details) =>
            _handleResizeUpdate(controller, component.id, details),
        onPanEnd: (details) => _handleResizeEnd(controller, component.id),
        child: MouseRegion(
          cursor: getCursor(handle),
          child: Container(
            // Invisible container for hit testing
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  /// Show a context menu for component layering options
  static void _showContextMenu(
    TapDownDetails details,
    ComponentModel component,
    CanvasController controller,
  ) {
    // Ensure the component is selected when right-clicked
    controller.onComponentSelected(component);

    final position = details.globalPosition;

    showMenu(
      context: Get.context!,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          onTap: () => controller.bringToFront(component.id),
          child: const Row(
            children: [
              Icon(Icons.flip_to_front, size: 20),
              SizedBox(width: 8),
              Text('Bring to Front'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => controller.sendToBack(component.id),
          child: const Row(
            children: [
              Icon(Icons.flip_to_back, size: 20),
              SizedBox(width: 8),
              Text('Send to Back'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComponentOverlay extends StatelessWidget {
  final ComponentModel component;
  final CanvasController controller;
  final Size canvasSize;
  final double baseWidth;
  final double baseHeight;

  const _ComponentOverlay({
    required this.component,
    required this.controller,
    required this.canvasSize,
    required this.baseWidth,
    required this.baseHeight,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CanvasController>(
      id: 'overlay_${component.id}',
      builder: (_) {
        final isSelected = controller.selectedComponentIds.contains(
          component.id,
        );
        final isDragging =
            controller.isDraggingComponent &&
            controller.draggingComponentId == component.id;
        final isResizing =
            controller.isResizingComponent &&
            controller.resizingComponentId == component.id;
        final isEditing =
            controller.isEditingComponent &&
            controller.editingComponentId == component.id;

        if (isEditing) return const SizedBox.shrink();

        // Interaction state
        final interaction = controller.getInteractionState(component.id);

        double dx = 0;
        double dy = 0;
        double componentWidth = baseWidth;
        double componentHeight = baseHeight;

        // Apply transient updates
        if (interaction != null) {
          if (interaction.position != null) {
            dx = interaction.position!.dx - component.x;
            dy = interaction.position!.dy - component.y;
          }
          if (interaction.size != null) {
            componentWidth = interaction.size!.width;
            componentHeight = interaction.size!.height;
          }
        }

        final isHovered = controller.hoveredComponentId == component.id;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: MouseRegion(
            onEnter: (_) => controller.setHoveredComponent(component.id),
            onExit: (_) => controller.setHoveredComponent(null),
            child: SizedBox(
              width: componentWidth,
              height: componentHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main interaction area
                  ComponentOverlayManager._buildMainInteractionArea(
                    component: component,
                    controller: controller,
                    canvasSize: canvasSize,
                    width: componentWidth,
                    height: componentHeight,
                    isDragging: isDragging,
                    isResizing: isResizing,
                  ),

                  // Selection indicator (Show if Selected OR Hovered)
                  if (isSelected || isHovered)
                    ComponentOverlayManager._buildSelectionIndicator(
                      isDragging: isDragging,
                      isResizing: isResizing,
                      component: component,
                      controller: controller,
                      width: componentWidth,
                      height: componentHeight,
                      isSelected: isSelected, // Pass selection state
                    ),

                  // Edge detection zones (invisible, for cursor feedback) - Must persist during resize!
                  // Show these ONLY when selected to avoid cursor changing on just hover
                  if (isSelected && component.resizable && !isDragging)
                    ...ComponentOverlayManager._buildEdgeDetectionZones(
                      component: component,
                      controller: controller,
                      width: componentWidth,
                      height: componentHeight,
                    ),

                  // Resize handles (visible when selected) - Draw on top!
                  if (isSelected && component.resizable && !isDragging)
                    ...ComponentOverlayManager._buildResizeHandles(
                      component: component,
                      controller: controller,
                      width: componentWidth,
                      height: componentHeight,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
