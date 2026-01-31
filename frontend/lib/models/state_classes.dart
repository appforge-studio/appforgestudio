import 'package:flutter/material.dart';
import 'component_model.dart';

class _Undefined {
  const _Undefined();
}

class CanvasState {
  final List<ComponentModel> components;
  final Size canvasSize;
  final bool isDragging;

  const CanvasState({
    this.components = const [],
    this.canvasSize = const Size(375, 812), // iPhone 12 size
    this.isDragging = false,
  });

  CanvasState copyWith({
    List<ComponentModel>? components,
    Size? canvasSize,
    bool? isDragging,
  }) {
    return CanvasState(
      components: components ?? this.components,
      canvasSize: canvasSize ?? this.canvasSize,
      isDragging: isDragging ?? this.isDragging,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'components': components.map((c) => c.toJson()).toList(),
      'canvasSize': {'width': canvasSize.width, 'height': canvasSize.height},
      'isDragging': isDragging,
    };
  }
}

class PropertyEditorState {
  final ComponentModel? selectedComponent;
  final bool isVisible;

  const PropertyEditorState({this.selectedComponent, this.isVisible = false});

  PropertyEditorState copyWith({
    Object? selectedComponent = const _Undefined(),
    bool? isVisible,
  }) {
    return PropertyEditorState(
      selectedComponent: selectedComponent is _Undefined
          ? this.selectedComponent
          : selectedComponent as ComponentModel?,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedComponent': selectedComponent?.toJson(),
      'isVisible': isVisible,
    };
  }
}

/// Transient state for component interaction (drag/resize)
/// This tracks temporary changes without committing to the main component model
/// to avoid expensive tree rebuilds.
class ComponentInteractionState {
  final Offset? position;
  final Size? size;

  const ComponentInteractionState({this.position, this.size});

  factory ComponentInteractionState.empty() {
    return const ComponentInteractionState();
  }

  ComponentInteractionState copyWith({Offset? position, Size? size}) {
    return ComponentInteractionState(
      position: position ?? this.position,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComponentInteractionState &&
        other.position == position &&
        other.size == size;
  }

  @override
  int get hashCode => position.hashCode ^ size.hashCode;
}
