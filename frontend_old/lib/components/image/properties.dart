import 'package:flutter/material.dart';
import '../../models/common_property.dart';
import '../../models/component_properties.dart';

class ImageProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
      const StringProperty(
        key: 'source',
        displayName: 'Image Source',
        value: 'https://via.placeholder.com/150',
      ),
      const NumberProperty(
        key: 'width',
        displayName: 'Width',
        value: 150.0,
        min: 10.0,
        max: 500.0,
      ),
      const NumberProperty(
        key: 'height',
        displayName: 'Height',
        value: 150.0,
        min: 10.0,
        max: 500.0,
      ),
      DropdownProperty<BoxFit>(
        key: 'fit',
        displayName: 'Image Fit',
        value: BoxFit.cover,
        options: BoxFit.values,
        displayText: (fit) => fit.name,
      ),
      const NumberProperty(
        key: 'borderRadius',
        displayName: 'Border Radius',
        value: 0.0,
        min: 0.0,
        max: 50.0,
      ),
    ]);
  }
}