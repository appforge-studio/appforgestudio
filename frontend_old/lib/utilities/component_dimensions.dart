import 'package:flutter/material.dart';
import '../models/component_model.dart';
import '../models/enums.dart';

/// Utility class for calculating component dimensions
class ComponentDimensions {
  /// Get the width of a component based on its type and properties
  static double? getWidth(ComponentModel component) {
    switch (component.type) {
      case ComponentType.container:
        return component.properties.shouldApplyProperty('width')
            ? (component.properties.getProperty<double>('width') ?? 100.0)
            : null;
      case ComponentType.text:
        return 120.0; // estimated - could be enhanced with text measurement
      case ComponentType.image:
        return component.properties.shouldApplyProperty('width')
            ? (component.properties.getProperty<double>('width') ?? 150.0)
            : null;
    }
  }

  /// Get the height of a component based on its type and properties
  static double? getHeight(ComponentModel component) {
    switch (component.type) {
      case ComponentType.container:
        return component.properties.shouldApplyProperty('height')
            ? (component.properties.getProperty<double>('height') ?? 100.0)
            : null;
      case ComponentType.text:
        return 40.0; // estimated - could be enhanced with text measurement
      case ComponentType.image:
        return component.properties.shouldApplyProperty('height')
            ? (component.properties.getProperty<double>('height') ?? 150.0)
            : null;
    }
  }

  /// Get both width and height as a Size object
  /// Get both width and height as a Size object
  static Size? getSize(ComponentModel component) {
    final w = getWidth(component);
    final h = getHeight(component);
    if (w == null || h == null) return null;
    return Size(w, h);
  }
}
