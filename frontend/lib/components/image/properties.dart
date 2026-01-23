import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import 'package:flutter/painting.dart'; // Needed for Alignment

class ImageProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
            const StringProperty(
        key: 'source',
        displayName: 'Source',
        value: 'https://via.placeholder.com/150',
        group: 'Image',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'width',
        displayName: 'Width',
        value: 150,
        min: 0.0,
        max: 1000.0,
        group: 'Layout',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'height',
        displayName: 'Height',
        value: 150,
        min: 0.0,
        max: 1000.0,
        group: 'Layout',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'borderRadius',
        displayName: 'Radius',
        value: 0,
        min: 0.0,
        max: 1000.0,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
    ]);
  }

  static Map<String, String? Function(dynamic)> get validators => {
    'source': (value) => value is String ? null : 'source must be a string',
    'width': (value) => value is num ? null : 'width must be a number',
    'height': (value) => value is num ? null : 'height must be a number',
    'borderRadius': (value) => value is num ? null : 'borderRadius must be a number',
  };
}
