import 'package:appforge/components/component_factory.dart';
import 'package:flutter/material.dart';
import '../models/component_model.dart';

/// Interface for handling drag and drop operations
abstract class DragDropHandler {
  void onDragStart(ComponentType type);
  void onDragUpdate(Offset position);
  void onDragEnd(Offset position, ComponentModel? component);
}

/// Interface for handling component selection
abstract class SelectionHandler {
  void onComponentSelected(ComponentModel component);
  void onComponentDeselected();
  void onComponentPropertiesChanged(ComponentModel component);
}

/// Interface for property editors
abstract class PropertyEditor<T> {
  Widget buildPropertyFields(T properties, Function(T) onChanged);
  T getDefaultProperties();
  bool validateProperties(T properties);
}
