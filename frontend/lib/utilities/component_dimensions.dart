import 'package:flutter/material.dart';

import '../models/component_model.dart';

/// Utility class for calculating component dimensions
class ComponentDimensions {
  /// Get the width of a component based on its properties
  static double? getWidth(ComponentModel component) {
    if (component.properties.shouldApplyProperty('width')) {
      return component.properties.getProperty<double>('width');
    }
    return null;
  }

  /// Get the height of a component based on its properties
  static double? getHeight(ComponentModel component) {
    if (component.properties.shouldApplyProperty('height')) {
      return component.properties.getProperty<double>('height');
    }
    return null;
  }

  /// Get both width and height as a Size object
  static Size? getSize(ComponentModel component) {
    final w = getWidth(component);
    final h = getHeight(component);
    if (w == null || h == null) return null;
    return Size(w, h);
  }
}
