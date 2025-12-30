import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../models/component_model.dart';
import 'component_dimensions.dart';

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

  /// Build complete overlay for a single component
  static Widget buildComponentOverlay({
    required ComponentModel component,
    required CanvasController controller,
    required Size canvasSize,
  }) {
    final isSelected = controller.selectedComponent?.id == component.id;
    final isDragging =
        controller.isDraggingComponent &&
        controller.draggingComponentId == component.id;
    final isResizing =
        controller.isResizingComponent &&
        controller.resizingComponentId == component.id;

    final width = ComponentDimensions.getWidth(component);
    final height = ComponentDimensions.getHeight(component);

    // Use explicit size from properties if available,
    // otherwise fallback to measured detectedSize
    final componentWidth = width ?? component.detectedSize?.width ?? 0.0;
    final componentHeight = height ?? component.detectedSize?.height ?? 0.0;

    return Positioned(
      left: component.x,
      top: component.y,
      child: SizedBox(
        width: componentWidth,
        height: componentHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main interaction area
            _buildMainInteractionArea(
              component: component,
              controller: controller,
              canvasSize: canvasSize,
              width: componentWidth,
              height: componentHeight,
              isDragging: isDragging,
              isResizing: isResizing,
            ),

            // Selection indicator
            if (isSelected)
              _buildSelectionIndicator(
                isDragging: isDragging,
                isResizing: isResizing,
                component: component,
                controller: controller,
                width: componentWidth,
                height: componentHeight,
              ),

            // Resize handles (visible when selected)
            if (isSelected && component.resizable && !isDragging)
              ..._buildResizeHandles(
                component: component,
                controller: controller,
                width: componentWidth,
                height: componentHeight,
              ),

            // Edge detection zones (invisible, for cursor feedback)
            if (component.resizable && !isDragging && !isResizing)
              ..._buildEdgeDetectionZones(
                component: component,
                controller: controller,
                width: componentWidth,
                height: componentHeight,
              ),
          ],
        ),
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
          behavior: HitTestBehavior.opaque, // Block taps from reaching parent
          onTap: () {
            if (!isDragging && !isResizing) {
              debugPrint(
                '🎯 Component tap detected - selecting component ${component.id}',
              );
              controller.onComponentSelected(component);
            }
          },
          onSecondaryTapDown: (details) {
            _showContextMenu(details, component, controller);
          },
          onPanStart: (details) {
            if (!isResizing) {
              controller.onComponentSelected(component);
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
  }) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Visual border (non-interactive)
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDragging || isResizing
                      ? selectionColor.withValues(alpha: 0.8)
                      : selectionColor,
                  width: isDragging || isResizing ? 3.0 : 2.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: isDragging || isResizing
                    ? [
                        BoxShadow(
                          color: selectionColor.withValues(alpha: 0.3),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          // Interactive border zones for resizing
          if (component.resizable && !isDragging)
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
      ),
      _buildResizeHandle(
        'ne',
        width - handleSize / 2,
        -handleSize / 2,
        controller,
        component.id,
      ),
      _buildResizeHandle(
        'sw',
        -handleSize / 2,
        height - handleSize / 2,
        controller,
        component.id,
      ),
      _buildResizeHandle(
        'se',
        width - handleSize / 2,
        height - handleSize / 2,
        controller,
        component.id,
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
  ) {
    final isActiveHandle =
        controller.isResizingComponent &&
        controller.resizingComponentId == componentId &&
        controller.resizeHandle == handle;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (details) =>
            _handleResizeStart(controller, componentId, handle),
        onPanUpdate: (details) =>
            _handleResizeUpdate(controller, componentId, details),
        onPanEnd: (details) => _handleResizeEnd(controller, componentId),
        child: MouseRegion(
          cursor: getCursor(handle),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isActiveHandle ? handleSize * 1.2 : handleSize,
            height: isActiveHandle ? handleSize * 1.2 : handleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.blue,
                width: isActiveHandle ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(handleSize / 2),
              boxShadow: [
                // BoxShadow(
                //   color: Colors.black.withValues(
                //     alpha: isActiveHandle ? 0.3 : 0.2,
                //   ),
                //   blurRadius: isActiveHandle ? 4.0 : 2.0,
                //   offset: Offset(0, isActiveHandle ? 2 : 1),
                // ),
              ],
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

  // Drag handlers
  static void _handleDragStart(
    CanvasController controller,
    String componentId,
    DragStartDetails details,
  ) {
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
    // Get the CURRENT component state from controller (not the stale one from gesture start)
    final currentComponent = controller.getComponentById(component.id);
    if (currentComponent == null) return;

    // Calculate new position with boundary constraints using CURRENT position
    final newX = (currentComponent.x + details.delta.dx).clamp(
      0.0,
      canvasSize.width - width,
    );
    final newY = (currentComponent.y + details.delta.dy).clamp(
      0.0,
      canvasSize.height - height,
    );

    // Update component position
    final updatedComponent = currentComponent.copyWith(x: newX, y: newY);
    controller.updateComponent(updatedComponent);
  }

  static void _handleDragEnd(
    CanvasController controller,
    String componentId,
    DragEndDetails details,
  ) {
    controller.setDragState(componentId, false);
  }

  // Resize handlers
  static void _handleResizeStart(
    CanvasController controller,
    String componentId,
    String handle,
  ) {
    controller.setResizeState(componentId, true, handle: handle);
  }

  static void _handleResizeUpdate(
    CanvasController controller,
    String componentId,
    details,
  ) {
    if (controller.isResizingComponent &&
        controller.resizingComponentId == componentId) {
      controller.resizeComponent(
        componentId,
        details.delta.dx,
        details.delta.dy,
      );
    }
  }

  static void _handleResizeEnd(
    CanvasController controller,
    String componentId,
  ) {
    if (controller.isResizingComponent &&
        controller.resizingComponentId == componentId) {
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
