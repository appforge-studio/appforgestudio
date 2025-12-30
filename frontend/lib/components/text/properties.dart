import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import 'package:flutter/painting.dart'; // Needed for Alignment

class TextProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
            const StringProperty(
        key: 'content',
        displayName: 'content',
        value: 'Sample Text',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'fontSize',
        displayName: 'fontSize',
        value: 16,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
      const ComponentColorProperty(
        key: 'color',
        displayName: 'color',
        value: XDColor(
             ['#000000'],
             type: ColorType.solid,
             stops: [],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
        ),
        enable: Enabled(show: true, enabled: true),
      ),
      const StringProperty(
        key: 'fontFamily',
        displayName: 'fontFamily',
        value: 'Roboto',
        enable: Enabled(show: true, enabled: true),
      ),
    ]);
  }
}
