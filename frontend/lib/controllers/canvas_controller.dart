import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';

import '../models/component_model.dart';
import '../models/alignment_guide_model.dart'
    as guide_model; // Import AlignmentGuide with prefix
import 'screens_controller.dart';
import '../models/state_classes.dart';
import '../utilities/interfaces.dart';
import '../components/component_factory.dart';
import '../utilities/component_dimensions.dart';
import '../utilities/component_overlay_manager.dart';
import '../services/arri_client.rpc.dart';
import '../services/socket_service.dart';
import '../bindings/app_bindings.dart';

class CanvasController extends GetxController
    implements SelectionHandler, DragDropHandler {
  final Rx<CanvasState> _state = const CanvasState().obs;

  // Auto-save timer
  Timer? _autoSaveTimer;

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

  // Selection state
  final RxSet<String> _selectedComponentIds = <String>{}.obs;
  final Rx<ComponentModel?> _selectedComponent = Rx<ComponentModel?>(null);
  final RxBool _isPropertyEditorVisible = false.obs;

  // Cursor state tracking
  final Rx<SystemMouseCursor> _currentCursor = SystemMouseCursors.basic.obs;

  // Edit mode state
  final RxString _editingComponentId = ''.obs;
  String get editingComponentId => _editingComponentId.value;
  bool get isEditingComponent => _editingComponentId.isNotEmpty;

  void setEditingComponent(String? id) {
    final oldId = _editingComponentId.value;
    _editingComponentId.value = id ?? '';

    if (oldId.isNotEmpty) {
      update(['overlay_$oldId']);
    }
    if (id != null && id.isNotEmpty) {
      update(['overlay_$id']);
    }
  }

  // Hover state
  final RxString _hoveredComponentId = ''.obs;
  String get hoveredComponentId => _hoveredComponentId.value;
  bool get isHoveringComponent => _hoveredComponentId.isNotEmpty;

  void setHoveredComponent(String? id) {
    final oldId = _hoveredComponentId.value;
    // Only update if changed prevents unnecessary rebuilds
    if (oldId == (id ?? '')) return;

    _hoveredComponentId.value = id ?? '';

    if (oldId.isNotEmpty) {
      update(['overlay_$oldId']);
    }
    if (id != null && id.isNotEmpty) {
      update(['overlay_$id']);
    }
  }

  // AI Session state
  final RxString _currentSessionId = ''.obs;
  String get currentSessionId => _currentSessionId.value;

  // Expose state for other controllers to listen to
  Rx<CanvasState> get stateStream => _state;

  // Getters for reactive state access
  CanvasState get state => _state.value;
  List<ComponentModel> get components => _state.value.components;
  Size get canvasSize => _state.value.canvasSize;
  ComponentModel? get selectedComponent => _selectedComponent.value;
  bool get isDragging => _state.value.isDragging;
  bool get isPropertyEditorVisible => _isPropertyEditorVisible.value;

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
  RxSet<String> get selectedComponentIds => _selectedComponentIds;

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

  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      _autoSave();
    });
  }

  void _autoSave() {
    if (Get.isRegistered<ScreensController>()) {
      final screensController = Get.find<ScreensController>();
      if (screensController.activeScreenId.value.isNotEmpty) {
        final jsonContent = jsonEncode(
          _state.value.components.map((c) => c.toJson()).toList(),
        );

        screensController.updateActiveScreenContent(jsonContent);
      } else {}
    } else {}
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

    _updateState(_state.value.copyWith(components: updatedComponents));
    _isPropertyEditorVisible.value = true;
  }

  void removeComponent(String componentId) {
    saveCheckpoint();
    final updatedComponents = _state.value.components
        .where((component) => component.id != componentId)
        .toList();

    _updateState(_state.value.copyWith(components: updatedComponents));

    if (_selectedComponent.value?.id == componentId) {
      _selectedComponent.value = null;
      _isPropertyEditorVisible.value = false;
    }
    _selectedComponentIds.remove(componentId);
  }

  void deleteSelectedComponents() {
    if (_selectedComponentIds.isEmpty) return;
    saveCheckpoint();

    final updatedComponents = _state.value.components
        .where((component) => !_selectedComponentIds.contains(component.id))
        .toList();

    _updateState(_state.value.copyWith(components: updatedComponents));
    _selectedComponent.value = null;
    _selectedComponentIds.clear();
    _isPropertyEditorVisible.value = false;
  }

  void updateComponent(ComponentModel updatedComponent) {
    final updatedComponents = _state.value.components
        .map(
          (component) => component.id == updatedComponent.id
              ? updatedComponent
              : component,
        )
        .toList();

    _updateState(_state.value.copyWith(components: updatedComponents));
    if (_selectedComponent.value?.id == updatedComponent.id) {
      _selectedComponent.value = updatedComponent;
    }
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

  // ... (skipping lines)

  /// Update the measured size of a component (from the visual layer)
  void updateComponentMeasuredSize(String componentId, Size size) {
    final component = getComponentById(componentId);
    if (component != null && (component.detectedSize != size)) {
      component.detectedSize = size;
      _state.refresh(); // Trigger UI update for overlays
    }
  }

  // Alignment Guides
  final RxList<guide_model.AlignmentGuide> _activeGuides =
      <guide_model.AlignmentGuide>[].obs;
  List<guide_model.AlignmentGuide> get activeGuides => _activeGuides;

  void clearGuides() {
    if (_activeGuides.isNotEmpty) {
      _activeGuides.clear();
    }
  }

  // Move component with snapping
  void moveComponentWithSnapping(
    String componentId,
    double deltaX,
    double deltaY,
  ) {
    try {
      final component = getComponentById(componentId);
      if (component == null) return;

      final interaction = getInteractionState(componentId);
      final currentX = interaction?.position?.dx ?? component.x;
      final currentY = interaction?.position?.dy ?? component.y;

      final width =
          interaction?.size?.width ??
          ComponentDimensions.getWidth(component) ??
          component.detectedSize?.width ??
          100.0;
      final height =
          interaction?.size?.height ??
          ComponentDimensions.getHeight(component) ??
          component.detectedSize?.height ??
          100.0;

      // Raw new position without snapping
      double newX = currentX + deltaX;
      double newY = currentY + deltaY;

      // Reset guides
      _activeGuides.clear();

      // Only snap if we are moving a single component (for simplicity initially)
      // or if it's the primary selection. Multi-selection snapping is complex.
      // We will snap the *primary* component (the one being dragged usually)

      const double snapThreshold = 5.0;

      // Calculate snap candidates
      // We check against canvas center and other components

      double? snappedX;
      double? snappedY;

      // 1. Vertical Guides (X alignments)
      // Candidates on the moving component: Left, Center, Right
      final myLeft = newX;
      final myCenter = newX + width / 2;
      final myRight = newX + width;

      // Canvas Center X
      final canvasCenterX = canvasSize.width / 2;

      if ((myCenter - canvasCenterX).abs() < snapThreshold) {
        snappedX = canvasCenterX - width / 2;
        _activeGuides.add(
          guide_model.AlignmentGuide(
            position: canvasCenterX,
            axis:
                guide_model.Axis.vertical, // fixed: using Axis enum from model
            isCenter: true,
          ),
        );
      } else if ((myLeft - canvasCenterX).abs() < snapThreshold) {
        snappedX = canvasCenterX;
        _activeGuides.add(
          guide_model.AlignmentGuide(
            position: canvasCenterX,
            axis: guide_model.Axis.vertical,
            isCenter: true,
          ),
        );
      } else if ((myRight - canvasCenterX).abs() < snapThreshold) {
        snappedX = canvasCenterX - width;
        _activeGuides.add(
          guide_model.AlignmentGuide(
            position: canvasCenterX,
            axis: guide_model.Axis.vertical,
            isCenter: true,
          ),
        );
      }

      // Other components X
      if (snappedX == null) {
        for (final other in components) {
          if (other.id == componentId ||
              _selectedComponentIds.contains(other.id))
            continue; // Don't snap to self or other moving selection

          final otherWidth =
              other.detectedSize?.width ??
              ComponentDimensions.getWidth(other) ??
              100.0;
          final otherLeft = other.x;
          final otherCenter = other.x + otherWidth / 2;
          final otherRight = other.x + otherWidth;

          // Check Left to Left/Right/Center
          if ((myLeft - otherLeft).abs() < snapThreshold) {
            snappedX = otherLeft;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherLeft,
                axis: guide_model.Axis.vertical,
              ),
            );
          } else if ((myLeft - otherRight).abs() < snapThreshold) {
            snappedX = otherRight;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherRight,
                axis: guide_model.Axis.vertical,
              ),
            );
          } else if ((myLeft - otherCenter).abs() < snapThreshold) {
            snappedX = otherCenter;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherCenter,
                axis: guide_model.Axis.vertical,
              ),
            );
          }
          // Check Right to Left/Right/Center
          else if ((myRight - otherLeft).abs() < snapThreshold) {
            snappedX = otherLeft - width;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherLeft,
                axis: guide_model.Axis.vertical,
              ),
            );
          } else if ((myRight - otherRight).abs() < snapThreshold) {
            snappedX = otherRight - width;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherRight,
                axis: guide_model.Axis.vertical,
              ),
            );
          } else if ((myRight - otherCenter).abs() < snapThreshold) {
            snappedX = otherCenter - width;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherCenter,
                axis: guide_model.Axis.vertical,
              ),
            );
          }
          // Check Center to Left/Right/Center
          else if ((myCenter - otherLeft).abs() < snapThreshold) {
            snappedX = otherLeft - width / 2;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherLeft,
                axis: guide_model.Axis.vertical,
              ),
            );
          } else if ((myCenter - otherRight).abs() < snapThreshold) {
            snappedX = otherRight - width / 2;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherRight,
                axis: guide_model.Axis.vertical,
              ),
            );
          } else if ((myCenter - otherCenter).abs() < snapThreshold) {
            snappedX = otherCenter - width / 2;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherCenter,
                axis: guide_model.Axis.vertical,
              ),
            );
          }

          if (snappedX != null)
            break; // Found a snap, stop looking (simple greedy)
        }
      }

      // 2. Horizontal Guides (Y alignments)
      // Candidates: Top, Center, Bottom
      final myTop = newY;
      final myMid = newY + height / 2;
      final myBottom = newY + height;

      // Canvas Center Y
      final canvasCenterY = canvasSize.height / 2;

      if ((myMid - canvasCenterY).abs() < snapThreshold) {
        snappedY = canvasCenterY - height / 2;
        _activeGuides.add(
          guide_model.AlignmentGuide(
            position: canvasCenterY,
            axis: guide_model.Axis.horizontal,
            isCenter: true,
          ),
        );
      } else if ((myTop - canvasCenterY).abs() < snapThreshold) {
        snappedY = canvasCenterY;
        _activeGuides.add(
          guide_model.AlignmentGuide(
            position: canvasCenterY,
            axis: guide_model.Axis.horizontal,
            isCenter: true,
          ),
        );
      } else if ((myBottom - canvasCenterY).abs() < snapThreshold) {
        snappedY = canvasCenterY - height;
        _activeGuides.add(
          guide_model.AlignmentGuide(
            position: canvasCenterY,
            axis: guide_model.Axis.horizontal,
            isCenter: true,
          ),
        );
      }

      // Other components Y
      if (snappedY == null) {
        for (final other in components) {
          if (other.id == componentId ||
              _selectedComponentIds.contains(other.id))
            continue;

          final otherHeight =
              other.detectedSize?.height ??
              ComponentDimensions.getHeight(other) ??
              100.0;
          final otherTop = other.y;
          final otherMid = other.y + otherHeight / 2;
          final otherBottom = other.y + otherHeight;

          // Check Top to Top/Bottom/Mid
          if ((myTop - otherTop).abs() < snapThreshold) {
            snappedY = otherTop;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherTop,
                axis: guide_model.Axis.horizontal,
              ),
            );
          } else if ((myTop - otherBottom).abs() < snapThreshold) {
            snappedY = otherBottom;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherBottom,
                axis: guide_model.Axis.horizontal,
              ),
            );
          } else if ((myTop - otherMid).abs() < snapThreshold) {
            snappedY = otherMid;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherMid,
                axis: guide_model.Axis.horizontal,
              ),
            );
          }
          // Check Bottom ...
          else if ((myBottom - otherTop).abs() < snapThreshold) {
            snappedY = otherTop - height;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherTop,
                axis: guide_model.Axis.horizontal,
              ),
            );
          } else if ((myBottom - otherBottom).abs() < snapThreshold) {
            snappedY = otherBottom - height;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherBottom,
                axis: guide_model.Axis.horizontal,
              ),
            );
          } else if ((myBottom - otherMid).abs() < snapThreshold) {
            snappedY = otherMid - height;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherMid,
                axis: guide_model.Axis.horizontal,
              ),
            );
          }
          // Check Mid ...
          else if ((myMid - otherTop).abs() < snapThreshold) {
            snappedY = otherTop - height / 2;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherTop,
                axis: guide_model.Axis.horizontal,
              ),
            );
          } else if ((myMid - otherBottom).abs() < snapThreshold) {
            snappedY = otherBottom - height / 2;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherBottom,
                axis: guide_model.Axis.horizontal,
              ),
            );
          } else if ((myMid - otherMid).abs() < snapThreshold) {
            snappedY = otherMid - height / 2;
            _activeGuides.add(
              guide_model.AlignmentGuide(
                position: otherMid,
                axis: guide_model.Axis.horizontal,
              ),
            );
          }

          if (snappedY != null) break;
        }
      }

      // Apply snap if found
      // DISABLE SNAPPING: User requested guidelines only, no actual snapping.
      // if (snappedX != null) newX = snappedX;
      // if (snappedY != null) newY = snappedY;

      // Clamp to canvas
      newX = newX.clamp(
        0.0,
        canvasSize.width - (snappedX != null ? 0 : 20),
      ); // Loose clamp if snapping? No, strict clamp.
      newX = newX.clamp(0.0, canvasSize.width - width);
      newY = newY.clamp(0.0, canvasSize.height - height);

      updateInteraction(componentId, position: Offset(newX, newY));

      // Apply delta to other selected components (relative move)
      // If we snapped, the delta is different from the input delta.
      final appliedDeltaX = newX - currentX;
      final appliedDeltaY = newY - currentY;

      for (final id in _selectedComponentIds) {
        if (id == componentId) continue;

        // Move others by the same *effective* delta
        final otherInteraction = getInteractionState(id);
        final otherComp = getComponentById(id);
        if (otherComp == null) continue;

        final ox = otherInteraction?.position?.dx ?? otherComp.x;
        final oy = otherInteraction?.position?.dy ?? otherComp.y;

        updateInteraction(
          id,
          position: Offset(ox + appliedDeltaX, oy + appliedDeltaY),
        );
      }
    } catch (_) {}
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
    update(['overlay_$componentId']);
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
    update(['overlay_$componentId']);
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
      if (_resizeHandle.value.length > 1) {}

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
    } catch (_) {}
  }

  // Handle component resizing
  void resizeComponent(String componentId, double deltaX, double deltaY) {
    final component = getComponentById(componentId);
    if (component == null || !component.resizable) {
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
    _updateState(_state.value.copyWith(components: []));
    _selectedComponent.value = null;
    _isPropertyEditorVisible.value = false;
    _selectedComponentIds.clear();
  }

  @override
  void onComponentSelected(ComponentModel component) {
    // Selection doesn't need checkpoint anymore - much faster
    // saveCheckpoint();

    // Check for shift key
    final isShiftPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.shiftRight,
        );

    if (isShiftPressed) {
      // Toggle selection
      final currentSelection = Set<String>.from(_selectedComponentIds);
      if (currentSelection.contains(component.id)) {
        currentSelection.remove(component.id);
      } else {
        currentSelection.add(component.id);
      }
      _selectMultipleComponents(currentSelection);

      // If we deselect the current "primary" component, we need to update the primary selection
      // _selectMultipleComponents handles setting the last added one as primary,
      // but if we removed one, we might need to fallback to another one or null.
      // Actually _selectMultipleComponents logic:
      // if (ids.isNotEmpty) { primarySelection = ... firstWhereOrNull((c) => c.id == ids.last); }
      // The 'ids' set passed here is unordered really, but Set implementation in Dart preserves insertion order slightly?
      // No, Set is not ordered. But we are creating a new Set.from existing ones.
      // Ideally, we should maintain an ordered list of selection for proper "primary" selection.
      // But for now, relying on _selectMultipleComponents to pick *some* primary is fine.
    } else {
      // If we select a different component, exit edit mode
      if (editingComponentId != component.id) {
        setEditingComponent(null);
      }

      // Single selection click (replace existing selection)
      _selectMultipleComponents({component.id});
    }
  }

  @override
  void onComponentDeselected() {
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
    update(['overlay_$componentId']);
  }

  void clearInteraction(String componentId) {
    _interactionUpdates.remove(componentId);
    update(['overlay_$componentId']);
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

  // Clipboard State
  List<Map<String, dynamic>> _clipboard = [];

  void copySelection() {
    if (_selectedComponentIds.isEmpty) return;

    _clipboard = _state.value.components
        .where((c) => _selectedComponentIds.contains(c.id))
        .map((c) => c.toJson())
        .toList();
  }

  void cutSelection() {
    if (_selectedComponentIds.isEmpty) return;
    copySelection();
    deleteSelectedComponents();
  }

  void pasteFromClipboard() {
    if (_clipboard.isEmpty) return;

    saveCheckpoint();

    final newComponents = <ComponentModel>[];
    final newSelectedIds = <String>{};

    // Calculate offset to place pasted items slightly shifted from original
    // If we paste multiple times, we might want to increase offset, but for now simple fixed offset is fine
    // Or we could track the center of the viewport? For now simple offset +20, +20
    const double pasteOffset = 20.0;

    for (final componentJson in _clipboard) {
      try {
        final newJson = Map<String, dynamic>.from(componentJson);

        // Generate new ID
        final newId = const Uuid().v4();
        newJson['id'] = newId;

        // Apply offset
        if (newJson['x'] != null)
          newJson['x'] = (newJson['x'] as num) + pasteOffset;
        if (newJson['y'] != null)
          newJson['y'] = (newJson['y'] as num) + pasteOffset;

        final newComponent = ComponentFactory.fromJson(newJson);

        newComponents.add(newComponent);
        newSelectedIds.add(newId);
      } catch (_) {}
    }

    if (newComponents.isNotEmpty) {
      final updatedComponents = List<ComponentModel>.from(
        _state.value.components,
      )..addAll(newComponents);

      _updateState(_state.value.copyWith(components: updatedComponents));

      // Select the pasted components
      _selectMultipleComponents(newSelectedIds);
    }
  }

  // Persistence
  void loadFromJson(String jsonContent) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonContent);
      final loadedComponents = decoded
          .map((item) => ComponentFactory.fromJson(item))
          .toList();

      // Clear history for new screen
      _undoStack.clear();
      _redoStack.clear();

      // Update state without triggering saveCheckpoint
      _updateState(
        _state.value.copyWith(components: loadedComponents, isDragging: false),
      );

      // Reset selection
      _selectedComponent.value = null;
      _selectedComponentIds.clear();
      _isPropertyEditorVisible.value = false;
    } catch (_) {}
  }

  void _selectMultipleComponents(Set<String> ids) {
    final oldSelection = _selectedComponentIds.toSet();

    // Calculate changes
    final added = ids.difference(oldSelection);
    final removed = oldSelection.difference(ids);

    // If no changes, do nothing (avoids rebuilds)
    if (added.isEmpty && removed.isEmpty) return;

    ComponentModel? primarySelection;
    if (ids.isNotEmpty) {
      // Set the last one as primary for property editor
      primarySelection = components.firstWhereOrNull((c) => c.id == ids.last);
    }

    _selectedComponentIds.assignAll(ids);
    _selectedComponent.value = primarySelection;
    _isPropertyEditorVisible.value = ids.isNotEmpty;

    // Trigger updates only for affected components
    final updates = <String>[];
    for (final id in added) {
      updates.add('overlay_$id');
    }
    for (final id in removed) {
      updates.add('overlay_$id');
    }

    if (updates.isNotEmpty) {
      update(updates);
    }
  }

  void clearSelection() {
    // Capture current selection before clearing to update them
    final previouslySelected = _selectedComponentIds.toList();

    setEditingComponent(null);
    _selectedComponentIds.clear();
    _selectedComponent.value = null;
    _isPropertyEditorVisible.value = false;

    // Update previously selected components so they redraw as unselected
    if (previouslySelected.isNotEmpty) {
      update(previouslySelected.map((id) => 'overlay_$id').toList());
    }
  }

  // Utility methods

  void _updateState(CanvasState newState) {
    if (isClosed) return;
    _state.value = newState;
    _triggerAutoSave();
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

    if (componentsJson != null) {
      for (final componentJson in componentsJson) {
        try {
          final component = ComponentFactory.fromJson(
            componentJson as Map<String, dynamic>,
          );
          components.add(component);
        } catch (_) {
          // Skip invalid components
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
      } catch (_) {
        // Skip invalid selected component
      }
    }

    _updateState(
      CanvasState(
        components: components,
        canvasSize: canvasSize,
        isDragging: json['isDragging'] as bool? ?? false,
      ),
    );

    _selectedComponent.value = selectedComponent;
    _isPropertyEditorVisible.value =
        json['isPropertyEditorVisible'] as bool? ?? false;

    // Trigger auto-generation for image components
    _autoGenerateImages(components);
  }

  Future<void> _autoGenerateImages(List<ComponentModel> components) async {
    for (final component in components) {
      if (component.type == ComponentType.image) {
        final imagePrompt =
            component.properties.getProperty('imagePrompt') as String?;
        if (imagePrompt != null && imagePrompt.isNotEmpty) {
          // Check if we already have a generated image (optional, but good if we want to avoid re-gen on reload if it was already saved?
          // For now, let's assume if we are reloading from JSON, we might want to regenerate OR keeping existing URL.
          // However, standard flow suggests if 'source' is empty or placeholder, we might generate.
          // But the prompt implies "use the prompt to generate image 1 step at a time".
          // Let's always generate if there is a prompt, or maybe check if source is empty?
          // Usually design loading implies fresh state or restored state.
          // If restored state has a URL, we might skip?
          // But the user request "after loading the design use the prompt to generate image" implies action.
          // I will force generation to verify the flow.

          try {
            final client = Get.find<ArriClient>();
            final socketService = Get.find<SocketService>();

            // Define preview handler
            void onPreview(dynamic data) {
              if (isClosed) return;
              if (data != null && data['image'] != null) {
                final previewBase64 = data['image'] as String;
                // Update component source with preview
                final currentComponent = getComponentById(component.id);
                if (currentComponent != null) {
                  final updatedProps = currentComponent.properties
                      .updateProperty('source', previewBase64);
                  updateComponent(
                    currentComponent.copyWith(properties: updatedProps),
                  );
                }
              }
            }

            // Listen for previews
            socketService.on('preview', onPreview);

            // Call API
            // Using 4 steps as requested
            final genResult = await client.ai.generate_with_preview(
              GenerateWithPreviewParams(
                prompt: imagePrompt,
                steps: 4,
                width:
                    component.detectedSize?.width ??
                    (component.properties.getProperty('width') as num?)
                        ?.toDouble() ??
                    512.0,
                height:
                    component.detectedSize?.height ??
                    (component.properties.getProperty('height') as num?)
                        ?.toDouble() ??
                    512.0,
                socketId: socketService.socketId,
              ),
            );

            // Cleanup listener
            socketService.off('preview', onPreview);

            if (isClosed) return;

            // Handle final result
            if (genResult.success && genResult.url != null) {
              final fullUrl = AppBindings.getAssetUrl(genResult.url!);
              final currentComponent = getComponentById(component.id);
              if (currentComponent != null) {
                final finalProps = currentComponent.properties.updateProperty(
                  'source',
                  fullUrl,
                );
                updateComponent(
                  currentComponent.copyWith(properties: finalProps),
                );
              }
            }
          } catch (_) {}
        }
      }
    }
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    super.onClose();
  }
}
