import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
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

  // Box Selection State
  final Rx<Rect?> _boxSelectionRect = Rx<Rect?>(null);
  final RxBool _isBoxSelecting = false.obs;
  // Temporary storage for selection start point
  Offset? _boxSelectionStart;

  // Transient interaction state (for performance)
  // Maps component ID to current interaction delta/state
  final RxMap<String, ComponentInteractionState> _interactionUpdates =
      <String, ComponentInteractionState>{}.obs;

  // Cursor state tracking
  final Rx<SystemMouseCursor> _currentCursor = SystemMouseCursors.basic.obs;

  // AI Session state
  final RxString _currentSessionId = ''.obs;
  String get currentSessionId => _currentSessionId.value;

  // Expose state for other controllers to listen to
  Rx<CanvasState> get stateStream => _state;

  // Getters for reactive state access
  CanvasState get state => _state.value;
  List<ComponentModel> get components => _state.value.components;
  Size get canvasSize => _state.value.canvasSize;
  ComponentModel? get selectedComponent => _state.value.selectedComponent;
  bool get isDragging => _state.value.isDragging;
  bool get isPropertyEditorVisible => _state.value.isPropertyEditorVisible;

  // Interaction getters
  ComponentInteractionState? getInteractionState(String componentId) =>
      _interactionUpdates[componentId];

  // Component repositioning getters
  bool get isDraggingComponent => _isDraggingComponent.value;
  String get draggingComponentId => _draggingComponentId.value;

  // Component resizing getters
  bool get isResizingComponent => _isResizingComponent.value;
  String get resizingComponentId => _resizingComponentId.value;
  String get resizeHandle => _resizeHandle.value;

  // Helper to check if any component interaction is active
  bool get isInteractingWithComponent =>
      isDraggingComponent || isResizingComponent;

  // Box Selection getters
  Rect? get boxSelectionRect => _boxSelectionRect.value;
  bool get isBoxSelecting => _isBoxSelecting.value;
  // Multi-selection getter
  Set<String> get selectedComponentIds => _state.value.selectedComponentIds;

  // Cursor getter
  SystemMouseCursor get currentCursor => _currentCursor.value;

  // History State
  final RxList<CanvasState> _undoStack = <CanvasState>[].obs;
  final RxList<CanvasState> _redoStack = <CanvasState>[].obs;
  static const int _maxHistorySize = 50;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void saveCheckpoint() {
    if (_undoStack.length >= _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(_state.value);
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    final previousState = _undoStack.removeLast();
    _redoStack.add(_state.value);
    _updateState(previousState);
  }

  void redo() {
    if (!canRedo) return;
    final nextState = _redoStack.removeLast();
    _undoStack.add(_state.value);
    _updateState(nextState);
  }

  // Component CRUD operations
  void addComponent(ComponentModel component) {
    saveCheckpoint();
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
    saveCheckpoint();
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
        selectedComponentIds: _state.value.selectedComponentIds
            .where((id) => id != componentId)
            .toSet(),
        isPropertyEditorVisible: newSelectedComponent != null,
      ),
    );
  }

  void deleteSelectedComponents() {
    if (_state.value.selectedComponentIds.isEmpty) return;
    saveCheckpoint();

    final updatedComponents = _state.value.components
        .where(
          (component) =>
              !_state.value.selectedComponentIds.contains(component.id),
        )
        .toList();

    _updateState(
      _state.value.copyWith(
        components: updatedComponents,
        selectedComponent: null,
        selectedComponentIds: {},
        isPropertyEditorVisible: false,
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
    saveCheckpoint();
    final component = getComponentById(componentId);
    if (component == null) return;

    final updatedComponents = List<ComponentModel>.from(_state.value.components)
      ..removeWhere((c) => c.id == componentId)
      ..add(component);

    _updateState(_state.value.copyWith(components: updatedComponents));
  }

  void sendToBack(String componentId) {
    saveCheckpoint();
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
    if (isDragging) saveCheckpoint();
    _isDraggingComponent.value = isDragging;
    _draggingComponentId.value = isDragging ? componentId : '';
    if (!isDragging) {
      _dragStartPosition.value = null;
      _currentCursor.value = SystemMouseCursors.basic;
    } else {
      _currentCursor.value = SystemMouseCursors.grabbing;
    }
  }

  // Resize state management
  void setResizeState(
    String componentId,
    bool isResizing, {
    String handle = '',
  }) {
    if (isResizing) saveCheckpoint();
    _isResizingComponent.value = isResizing;
    _resizingComponentId.value = isResizing ? componentId : '';
    _resizeHandle.value = handle;

    if (isResizing) {
      final component = getComponentById(componentId);
      if (component != null) {
        _originalSize.value = ComponentDimensions.getSize(component);
      }
      // Update cursor for resize operation
      _updateCursorForResize(handle);
    } else {
      _originalSize.value = null;
      _currentCursor.value = SystemMouseCursors.basic;
    }
  }

  // Update cursor based on resize handle
  void _updateCursorForResize(String handle) {
    _currentCursor.value = ComponentOverlayManager.getCursor(handle);
  }

  // Handle transient component resizing (updates interaction state only)
  void resizeComponentTransient(
    String componentId,
    double deltaX,
    double deltaY,
  ) {
    try {
      final component = getComponentById(componentId);
      if (component == null) return;

      final interaction = getInteractionState(componentId);
      final currentWidth =
          interaction?.size?.width ??
          ComponentDimensions.getWidth(component) ??
          component.detectedSize?.width ??
          100.0;
      final currentHeight =
          interaction?.size?.height ??
          ComponentDimensions.getHeight(component) ??
          component.detectedSize?.height ??
          100.0;
      final currentX = interaction?.position?.dx ?? component.x;
      final currentY = interaction?.position?.dy ?? component.y;

      // Log for debugging diagonal resize issues
      if (_resizeHandle.value.length > 1) {
        debugPrint(
          'Resize diag: $_resizeHandle, delta: ($deltaX, $deltaY), curr: $currentWidth x $currentHeight',
        );
      }

      double newWidth = currentWidth;
      double newHeight = currentHeight;
      double newX = currentX;
      double newY = currentY;

      // Use consistent resize handle from controller state
      final handle = _resizeHandle.value;

      switch (handle) {
        case 'se': // Southeast - resize width and height
          newWidth = (currentWidth + deltaX).clamp(
            20.0,
            canvasSize.width - currentX,
          );
          newHeight = (currentHeight + deltaY).clamp(
            20.0,
            canvasSize.height - currentY,
          );
          break;
        case 'sw': // Southwest - resize width (left) and height
          newWidth = (currentWidth - deltaX).clamp(
            20.0,
            currentX + currentWidth,
          );
          newHeight = (currentHeight + deltaY).clamp(
            20.0,
            canvasSize.height - currentY,
          );
          newX = currentX + (currentWidth - newWidth);
          break;
        case 'ne': // Northeast - resize width and height (top)
          newWidth = (currentWidth + deltaX).clamp(
            20.0,
            canvasSize.width - currentX,
          );
          newHeight = (currentHeight - deltaY).clamp(
            20.0,
            currentY + currentHeight,
          );
          newY = currentY + (currentHeight - newHeight);
          break;
        case 'nw': // Northwest - resize width (left) and height (top)
          newWidth = (currentWidth - deltaX).clamp(
            20.0,
            currentX + currentWidth,
          );
          newHeight = (currentHeight - deltaY).clamp(
            20.0,
            currentY + currentHeight,
          );
          newX = currentX + (currentWidth - newWidth);
          newY = currentY + (currentHeight - newHeight);
          break;
        case 'e': // East - resize width only
          newWidth = (currentWidth + deltaX).clamp(
            20.0,
            canvasSize.width - currentX,
          );
          break;
        case 'w': // West - resize width (left) only
          newWidth = (currentWidth - deltaX).clamp(
            20.0,
            currentX + currentWidth,
          );
          newX = currentX + (currentWidth - newWidth);
          break;
        case 'n': // North - resize height (top) only
          newHeight = (currentHeight - deltaY).clamp(
            20.0,
            currentY + currentHeight,
          );
          newY = currentY + (currentHeight - newHeight);
          break;
        case 's': // South - resize height only
          newHeight = (currentHeight + deltaY).clamp(
            20.0,
            canvasSize.height - currentY,
          );
          break;
      }

      updateInteraction(
        componentId,
        position: Offset(newX, newY),
        size: Size(newWidth, newHeight),
      );
    } catch (e, stack) {
      debugPrint('Error in resizeComponentTransient: $e\n$stack');
    }
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
  }

  ComponentModel? getComponentById(String id) {
    return _state.value.components.firstWhereOrNull((c) => c.id == id);
  }

  // Canvas management
  void setCanvasSize(Size size) {
    _updateState(_state.value.copyWith(canvasSize: size));
  }

  void startNewSession() {
    _currentSessionId.value = const Uuid().v4();
  }

  void clearCanvas() {
    _currentSessionId.value = '';
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
    saveCheckpoint();
    // Single selection click (replace existing selection)
    _selectMultipleComponents({component.id});
  }

  @override
  void onComponentDeselected() {
    saveCheckpoint();
    clearSelection();
  }

  @override
  void onComponentPropertiesChanged(ComponentModel component) {
    saveCheckpoint();
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

  // Transient Interaction Methods (Performance)

  void startInteraction(String componentId) {
    if (!_interactionUpdates.containsKey(componentId)) {
      _interactionUpdates[componentId] = ComponentInteractionState.empty();
    }
  }

  void updateInteraction(String componentId, {Offset? position, Size? size}) {
    final current =
        _interactionUpdates[componentId] ?? ComponentInteractionState.empty();

    _interactionUpdates[componentId] = current.copyWith(
      position: position,
      size: size,
    );
  }

  void clearInteraction(String componentId) {
    _interactionUpdates.remove(componentId);
  }

  void commitInteraction(String componentId) {
    final interaction = _interactionUpdates[componentId];
    if (interaction == null) return;

    final component = getComponentById(componentId);
    if (component == null) {
      clearInteraction(componentId);
      return;
    }

    var updatedComponent = component;

    if (interaction.position != null) {
      updatedComponent = updatedComponent.copyWith(
        x: interaction.position!.dx,
        y: interaction.position!.dy,
      );
    }

    if (interaction.size != null) {
      // Update properties if size changed
      var updatedProperties = updatedComponent.properties
          .updateProperty('width', interaction.size!.width)
          .updateProperty('height', interaction.size!.height);

      if (updatedComponent.properties.getProperty('width') == null) {
        updatedProperties = updatedProperties.updatePropertyEnabled(
          'width',
          true,
        );
      }
      if (updatedComponent.properties.getProperty('height') == null) {
        updatedProperties = updatedProperties.updatePropertyEnabled(
          'height',
          true,
        );
      }

      updatedComponent = updatedComponent.copyWith(
        properties: updatedProperties,
      );
    }

    // Commit to main state
    updateComponent(updatedComponent);
    clearInteraction(componentId);
  }

  // Box Selection Logic

  void startBoxSelection(Offset startPos) {
    saveCheckpoint();
    _isBoxSelecting.value = true;
    _boxSelectionStart = startPos;
    _boxSelectionRect.value = Rect.fromPoints(startPos, startPos);

    // Clear existing selection unless shift is held (TODO: add shift support)
    // For now, simple behavior: start fresh
    clearSelection();
  }

  void updateBoxSelection(Offset currentPos) {
    if (!_isBoxSelecting.value || _boxSelectionStart == null) return;
    _boxSelectionRect.value = Rect.fromPoints(_boxSelectionStart!, currentPos);

    // Live selection update - select components as the box moves
    _updateSelectionFromRect(_boxSelectionRect.value!);
  }

  void endBoxSelection() {
    if (!_isBoxSelecting.value || _boxSelectionRect.value == null) return;

    // Final selection update
    _updateSelectionFromRect(_boxSelectionRect.value!);

    _isBoxSelecting.value = false;
    _boxSelectionRect.value = null;
    _boxSelectionStart = null;
  }

  /// Helper method to update selection based on selection rectangle
  void _updateSelectionFromRect(Rect selectionRect) {
    final selectedIds = <String>{};

    for (final component in components) {
      final width =
          component.detectedSize?.width ??
          ComponentDimensions.getWidth(component) ??
          100.0;
      final height =
          component.detectedSize?.height ??
          ComponentDimensions.getHeight(component) ??
          100.0;

      // Check if component intersects with selection box
      // (Using simple bounding box intersection)
      final componentRect = Rect.fromLTWH(
        component.x,
        component.y,
        width,
        height,
      );

      if (selectionRect.overlaps(componentRect)) {
        selectedIds.add(component.id);
      }
    }

    // Update selection live (even if empty, to deselect components that are no longer in the box)
    _selectMultipleComponents(selectedIds);
  }

  void _selectMultipleComponents(Set<String> ids) {
    ComponentModel? primarySelection;
    if (ids.isNotEmpty) {
      // Set the last one as primary for property editor
      primarySelection = components.firstWhereOrNull((c) => c.id == ids.last);
    }

    _updateState(
      _state.value.copyWith(
        selectedComponentIds: ids,
        selectedComponent: primarySelection, // Maintain backward compatibility
        isPropertyEditorVisible: ids.isNotEmpty,
      ),
    );
  }

  void clearSelection() {
    _updateState(
      _state.value.copyWith(
        selectedComponentIds: {},
        selectedComponent:
            null, // This sets it to _Undefined check manually if needed or utilize nullable logic in copyWith
        isPropertyEditorVisible: false,
      ),
    );
    // Ideally pass explicit null to reset selectedComponent via copyWith logic in state_classes
    // But copyWith handles _Undefined. We need to actually pass null.
    // The previous implementation of clearCanvas did: selectedComponent: null.
  }

  // Utility methods

  void _updateState(CanvasState newState) {
    _state.value = newState;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return _state.value.toJson();
  }

  void fromJson(Map<String, dynamic> json, {String? sessionId}) {
    if (sessionId != null) {
      _currentSessionId.value = sessionId;
    }
    final componentsJson = json['components'] as List<dynamic>?;
    final components = <ComponentModel>[];

    debugPrint(
      '📥 CanvasController: Loading design from JSON. Components found: ${componentsJson?.length}',
    );

    if (componentsJson != null) {
      for (final componentJson in componentsJson) {
        try {
          final component = ComponentFactory.fromJson(
            componentJson as Map<String, dynamic>,
          );
          components.add(component);
          debugPrint(
            '✅ Parsed component: ${component.id} (${component.type.name})',
          );
        } catch (e) {
          // Skip invalid components
          debugPrint('❌ Error parsing component: $e\nJSON: $componentJson');
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
