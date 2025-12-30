import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import 'package:flutter/painting.dart'; // Needed for Alignment

class ContainerProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
            const NumberProperty(
        key: 'width',
        displayName: 'width',
        value: 100,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'height',
        displayName: 'height',
        value: 100,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
      const ComponentColorProperty(
        key: 'backgroundColor',
        displayName: 'backgroundColor',
        value: XDColor(
             ['#FFFFFF'],
             type: ColorType.solid,
             stops: [],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
        ),
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
      const NumberProperty(
        key: 'padding',
        displayName: 'padding',
        value: 0,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
    ]);
  }
}
