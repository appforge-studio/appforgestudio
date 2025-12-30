import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/component_model.dart';
import '../models/state_classes.dart';
import '../utilities/interfaces.dart';
import '../components/component_factory.dart';
import '../utilities/component_dimensions.dart';
import '../utilities/component_overlay_manager.dart';

class CanvasController extends GetxController
    implements SelectionHandler, DragDropHandler {
  final Rx<CanvasState> _state = const CanvasState().obs;

  // Component repositioning state
  final RxBool _isDraggingComponent = false.obs;
  final RxString _draggingComponentId = ''.obs;
  final Rx<Offset?> _dragStartPosition = Rx<Offset?>(null);

  // Component resizing state
  final RxBool _isResizingComponent = false.obs;
  final RxString _resizingComponentId = ''.obs;
  final RxString _resizeHandle =
      ''.obs; // 'se', 'sw', 'ne', 'nw', 'e', 'w', 'n', 's'
  final Rx<Size?> _originalSize = Rx<Size?>(null);

  // Cursor state tracking
  final Rx<SystemMouseCursor> _currentCursor = SystemMouseCursors.basic.obs;

  // Expose state for other controllers to listen to
  Rx<CanvasState> get stateStream => _state;

  // Getters for reactive state access
  CanvasState get state => _state.value;
  List<ComponentModel> get components => _state.value.components;
  Size get canvasSize => _state.value.canvasSize;
  ComponentModel? get selectedComponent => _state.value.selectedComponent;
  bool get isDragging => _state.value.isDragging;
  bool get isPropertyEditorVisible => _state.value.isPropertyEditorVisible;

  // Component repositioning getters
  bool get isDraggingComponent => _isDraggingComponent.value;
  String get draggingComponentId => _draggingComponentId.value;

  // Component resizing getters
  bool get isResizingComponent => _isResizingComponent.value;
  String get resizingComponentId => _resizingComponentId.value;
  String get resizeHandle => _resizeHandle.value;

  // Cursor getter
  SystemMouseCursor get currentCursor => _currentCursor.value;

  // Component CRUD operations
  void addComponent(ComponentModel component) {
    final updatedComponents = List<ComponentModel>.from(_state.value.components)
      ..add(component);

    _updateState(
      _state.value.copyWith(
        components: updatedComponents,
        isPropertyEditorVisible: true,
      ),
    );
  }

  void removeComponent(String componentId) {
    final updatedComponents = _state.value.components
        .where((component) => component.id != componentId)
        .toList();

    ComponentModel? newSelectedComponent = _state.value.selectedComponent;
    if (newSelectedComponent?.id == componentId) {
      newSelectedComponent = null;
    }

    _updateState(
      _state.value.copyWith(
        components: updatedComponents,
        selectedComponent: newSelectedComponent,
        isPropertyEditorVisible: newSelectedComponent != null,
      ),
    );
  }

  void updateComponent(ComponentModel updatedComponent) {
    // Reduced logging for performance - only log significant position changes
    final positionChanged =
        _state.value.components
            .where((c) => c.id == updatedComponent.id)
            .map(
              (c) =>
                  (updatedComponent.x - c.x).abs() > 5 ||
                  (updatedComponent.y - c.y).abs() > 5,
            )
            .firstOrNull ??
        true;

    if (positionChanged) {
      debugPrint(
        '🔄 CONTROLLER: updateComponent(${updatedComponent.id}) → (${updatedComponent.x.toInt()}, ${updatedComponent.y.toInt()})',
      );
    }

    final updatedComponents = _state.value.components
        .map(
          (component) => component.id == updatedComponent.id
              ? updatedComponent
              : component,
        )
        .toList();

    ComponentModel? newSelectedComponent = _state.value.selectedComponent;
    if (newSelectedComponent?.id == updatedComponent.id) {
      newSelectedComponent = updatedComponent;
    }

    _updateState(
      _state.value.copyWith(
        components: updatedComponents,
        selectedComponent: newSelectedComponent,
      ),
    );
  }

  void updateComponentPosition(String componentId, double x, double y) {
    final component = _state.value.components.firstWhereOrNull(
      (c) => c.id == componentId,
    );

    if (component != null) {
      // Constrain position within canvas boundaries
      final constrainedX = x.clamp(0.0, _state.value.canvasSize.width - 50);
      final constrainedY = y.clamp(0.0, _state.value.canvasSize.height - 50);

      final updatedComponent = component.copyWith(
        x: constrainedX,
        y: constrainedY,
      );

      updateComponent(updatedComponent);
    }
  }

  void bringToFront(String componentId) {
    final component = getComponentById(componentId);
    if (component == null) return;

    final updatedComponents = List<ComponentModel>.from(_state.value.components)
      ..removeWhere((c) => c.id == componentId)
      ..add(component);

    _updateState(_state.value.copyWith(components: updatedComponents));
  }

  void sendToBack(String componentId) {
    final component = getComponentById(componentId);
    if (component == null) return;

    final updatedComponents = List<ComponentModel>.from(_state.value.components)
      ..removeWhere((c) => c.id == componentId)
      ..insert(0, component);

    _updateState(_state.value.copyWith(components: updatedComponents));
  }

  /// Update the measured size of a component (from the visual layer)
  void updateComponentMeasuredSize(String componentId, Size size) {
    final component = getComponentById(componentId);
    if (component != null &&
        (component.detectedSize?.width != size.width ||
            component.detectedSize?.height != size.height)) {
      component.detectedSize = size;
      _state.refresh(); // Trigger UI update for overlays
    }
  }

  // Simplified drag state management - used by json_dynamic_widget functions
  void setDragState(String componentId, bool isDragging) {
    debugPrint('🎮 CONTROLLER: setDragState($componentId, $isDragging)');
    debugPrint(
      '   Before: isDragging=${_isDraggingComponent.value}, draggingId=${_draggingComponentId.value}',
    );

    _isDraggingComponent.value = isDragging;
    _draggingComponentId.value = isDragging ? componentId : '';
    if (!isDragging) {
      _dragStartPosition.value = null;
      _currentCursor.value = SystemMouseCursors.basic;
      debugPrint('   Drag ended - cursor reset to basic');
    } else {
      _currentCursor.value = SystemMouseCursors.grabbing;
      debugPrint('   Drag started - cursor set to grabbing');
    }

    debugPrint(
      '   After: isDragging=${_isDraggingComponent.value}, draggingId=${_draggingComponentId.value}',
    );
  }

  // Resize state management
  void setResizeState(
    String componentId,
    bool isResizing, {
    String handle = '',
  }) {
    debugPrint(
      '🎮 CONTROLLER: setResizeState($componentId, $isResizing, handle: $handle)',
    );
    debugPrint(
      '   Before: isResizing=${_isResizingComponent.value}, resizingId=${_resizingComponentId.value}',
    );

    _isResizingComponent.value = isResizing;
    _resizingComponentId.value = isResizing ? componentId : '';
    _resizeHandle.value = handle;

    if (isResizing) {
      final component = getComponentById(componentId);
      if (component != null) {
        _originalSize.value = ComponentDimensions.getSize(component);
        debugPrint(
          '   Original size stored: ${_originalSize.value!.width.toInt()}x${_originalSize.value!.height.toInt()}',
        );
      }
      // Update cursor for resize operation
      _updateCursorForResize(handle);
      debugPrint('   Resize started - cursor set for handle: $handle');
    } else {
      _originalSize.value = null;
      _currentCursor.value = SystemMouseCursors.basic;
      debugPrint('   Resize ended - cursor reset to basic');
    }

    debugPrint(
      '   After: isResizing=${_isResizingComponent.value}, resizingId=${_resizingComponentId.value}',
    );
  }

  // Update cursor based on resize handle
  void _updateCursorForResize(String handle) {
    _currentCursor.value = ComponentOverlayManager.getCursor(handle);
  }

  // Handle component resizing
  void resizeComponent(String componentId, double deltaX, double deltaY) {
    final component = getComponentById(componentId);
    if (component == null || !component.resizable) {
      debugPrint('❌ Component $componentId not found or not resizable');
      return;
    }

    final handle = _resizeHandle.value;

    // Get current dimensions from the component with fallback for disabled properties
    final measuredWidth = ComponentDimensions.getWidth(component);
    final measuredHeight = ComponentDimensions.getHeight(component);

    final currentWidth =
        measuredWidth ??
        (canvasSize.width - component.x).clamp(20.0, canvasSize.width);
    final currentHeight =
        measuredHeight ??
        (canvasSize.height - component.y).clamp(20.0, canvasSize.height);

    double newWidth = currentWidth;
    double newHeight = currentHeight;
    double newX = component.x;
    double newY = component.y;

    // Calculate new dimensions based on resize handle using frame-to-frame deltas
    switch (handle) {
      case 'se': // Southeast - resize width and height
        newWidth = (currentWidth + deltaX).clamp(
          20.0,
          canvasSize.width - component.x,
        );
        newHeight = (currentHeight + deltaY).clamp(
          20.0,
          canvasSize.height - component.y,
        );
        break;
      case 'sw': // Southwest - resize width (left) and height
        newWidth = (currentWidth - deltaX).clamp(
          20.0,
          component.x + currentWidth,
        );
        newHeight = (currentHeight + deltaY).clamp(
          20.0,
          canvasSize.height - component.y,
        );
        newX = component.x + (currentWidth - newWidth);
        break;
      case 'ne': // Northeast - resize width and height (top)
        newWidth = (currentWidth + deltaX).clamp(
          20.0,
          canvasSize.width - component.x,
        );
        newHeight = (currentHeight - deltaY).clamp(
          20.0,
          component.y + currentHeight,
        );
        newY = component.y + (currentHeight - newHeight);
        break;
      case 'nw': // Northwest - resize width (left) and height (top)
        newWidth = (currentWidth - deltaX).clamp(
          20.0,
          component.x + currentWidth,
        );
        newHeight = (currentHeight - deltaY).clamp(
          20.0,
          component.y + currentHeight,
        );
        newX = component.x + (currentWidth - newWidth);
        newY = component.y + (currentHeight - newHeight);
        break;
      case 'e': // East - resize width only
        newWidth = (currentWidth + deltaX).clamp(
          20.0,
          canvasSize.width - component.x,
        );
        break;
      case 'w': // West - resize width (left) only
        newWidth = (currentWidth - deltaX).clamp(
          20.0,
          component.x + currentWidth,
        );
        newX = component.x + (currentWidth - newWidth);
        break;
      case 'n': // North - resize height (top) only
        newHeight = (currentHeight - deltaY).clamp(
          20.0,
          component.y + currentHeight,
        );
        newY = component.y + (currentHeight - newHeight);
        break;
      case 's': // South - resize height only
        newHeight = (currentHeight + deltaY).clamp(
          20.0,
          canvasSize.height - component.y,
        );
        break;
    }

    // Reduced logging frequency for resize updates
    final sizeChanged =
        (newWidth - currentWidth).abs() > 2 ||
        (newHeight - currentHeight).abs() > 2;
    if (sizeChanged) {
      debugPrint('🔧 RESIZE: $componentId, handle: $handle');
      debugPrint(
        '   ${currentWidth.toInt()}x${currentHeight.toInt()} → ${newWidth.toInt()}x${newHeight.toInt()}',
      );
    }

    // Update component properties with new dimensions
    // We must ensure the property is enabled since we are setting an explicit size
    var updatedProperties = component.properties
        .updateProperty('width', newWidth)
        .updateProperty('height', newHeight);

    if (measuredWidth == null) {
      updatedProperties = updatedProperties.updatePropertyEnabled(
        'width',
        true,
      );
    }
    if (measuredHeight == null) {
      updatedProperties = updatedProperties.updatePropertyEnabled(
        'height',
        true,
      );
    }

    final updatedComponent = component.copyWith(
      x: newX,
      y: newY,
      properties: updatedProperties,
    );

    updateComponent(updatedComponent);
    if (sizeChanged) {
      debugPrint('   ✅ Resize applied');
    }
  }

  ComponentModel? getComponentById(String id) {
    return _state.value.components.firstWhereOrNull((c) => c.id == id);
  }

  // Canvas management
  void setCanvasSize(Size size) {
    _updateState(_state.value.copyWith(canvasSize: size));
  }

  void clearCanvas() {
    _updateState(
      _state.value.copyWith(
        components: [],
        selectedComponent: null,
        isPropertyEditorVisible: false,
      ),
    );
  }

  // Selection management
  @override
  void onComponentSelected(ComponentModel component) {
    debugPrint(
      '🎮 CanvasController: onComponentSelected called with ${component.id}',
    );
    _updateState(
      _state.value.copyWith(
        selectedComponent: component,
        isPropertyEditorVisible: true,
      ),
    );
    debugPrint(
      '🎮 CanvasController: State updated - selectedComponent: ${_state.value.selectedComponent?.id}, isPropertyEditorVisible: ${_state.value.isPropertyEditorVisible}',
    );
  }

  @override
  void onComponentDeselected() {
    print(
      '🔄 Deselecting component - current selected: ${_state.value.selectedComponent?.id}',
    );
    _updateState(
      _state.value.copyWith(
        selectedComponent: null,
        isPropertyEditorVisible: false,
      ),
    );
    print(
      '🔄 After deselection - selected: ${_state.value.selectedComponent?.id}',
    );
  }

  @override
  void onComponentPropertiesChanged(ComponentModel component) {
    updateComponent(component);
  }

  // Drag and drop handling
  @override
  void onDragStart(ComponentType type) {
    _updateState(_state.value.copyWith(isDragging: true));
  }

  @override
  void onDragUpdate(Offset position) {
    // Update drag position if needed for visual feedback
    // This can be extended to show drag preview
  }

  @override
  void onDragEnd(Offset position, ComponentModel? component) {
    _updateState(_state.value.copyWith(isDragging: false));

    if (component != null) {
      // Component is provided when drag is accepted by canvas
      addComponent(component);
      onComponentSelected(component);
    }
    // If component is null, it means drag was cancelled or not accepted
  }

  // Utility methods

  void _updateState(CanvasState newState) {
    _state.value = newState;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return _state.value.toJson();
  }

  void fromJson(Map<String, dynamic> json) {
    final componentsJson = json['components'] as List<dynamic>?;
    final components = <ComponentModel>[];

    if (componentsJson != null) {
      for (final componentJson in componentsJson) {
        try {
          final component = ComponentFactory.fromJson(
            componentJson as Map<String, dynamic>,
          );
          components.add(component);
        } catch (e) {
          // Skip invalid components
          print('Error parsing component: $e');
        }
      }
    }

    final canvasSize = json['canvasSize'] != null
        ? Size(
            (json['canvasSize']['width'] as num).toDouble(),
            (json['canvasSize']['height'] as num).toDouble(),
          )
        : const Size(375, 812);

    final selectedComponentJson =
        json['selectedComponent'] as Map<String, dynamic>?;
    ComponentModel? selectedComponent;

    if (selectedComponentJson != null) {
      try {
        selectedComponent = ComponentFactory.fromJson(selectedComponentJson);
      } catch (e) {
        // Skip invalid selected component
        print('Error parsing selected component: $e');
      }
    }

    _updateState(
      CanvasState(
        components: components,
        canvasSize: canvasSize,
        selectedComponent: selectedComponent,
        isDragging: json['isDragging'] as bool? ?? false,
        isPropertyEditorVisible:
            json['isPropertyEditorVisible'] as bool? ?? false,
      ),
    );
  }
}
