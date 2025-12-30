import 'package:flutter/material.dart';
import 'component_model.dart';

class _Undefined {
  const _Undefined();
}

class CanvasState {
  final List<ComponentModel> components;
  final Size canvasSize;
  final ComponentModel? selectedComponent;
  final bool isDragging;
  final bool isPropertyEditorVisible;
  
  const CanvasState({
    this.components = const [],
    this.canvasSize = const Size(375, 812), // iPhone 12 size
    this.selectedComponent,
    this.isDragging = false,
    this.isPropertyEditorVisible = false,
  });
  
  CanvasState copyWith({
    List<ComponentModel>? components,
    Size? canvasSize,
    Object? selectedComponent = const _Undefined(),
    bool? isDragging,
    bool? isPropertyEditorVisible,
  }) {
    return CanvasState(
      components: components ?? this.components,
      canvasSize: canvasSize ?? this.canvasSize,
      selectedComponent: selectedComponent is _Undefined ? this.selectedComponent : selectedComponent as ComponentModel?,
      isDragging: isDragging ?? this.isDragging,
      isPropertyEditorVisible: isPropertyEditorVisible ?? this.isPropertyEditorVisible,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'components': components.map((c) => c.toJson()).toList(),
      'canvasSize': {
        'width': canvasSize.width,
        'height': canvasSize.height,
      },
      'selectedComponent': selectedComponent?.toJson(),
      'isDragging': isDragging,
      'isPropertyEditorVisible': isPropertyEditorVisible,
    };
  }
}

class PropertyEditorState {
  final ComponentModel? selectedComponent;
  final bool isVisible;
  
  const PropertyEditorState({
    this.selectedComponent,
    this.isVisible = false,
  });
  
  PropertyEditorState copyWith({
    Object? selectedComponent = const _Undefined(),
    bool? isVisible,
  }) {
    return PropertyEditorState(
      selectedComponent: selectedComponent is _Undefined ? this.selectedComponent : selectedComponent as ComponentModel?,
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