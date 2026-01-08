import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import 'package:flutter/painting.dart'; // Needed for Alignment

class ImageProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
            const StringProperty(
        key: 'source',
        displayName: 'source',
        value: 'https://via.placeholder.com/150',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'width',
        displayName: 'width',
        value: 150,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'height',
        displayName: 'height',
        value: 150,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'borderRadius',
        displayName: 'borderRadius',
        value: 0,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
    ]);
  }
}
