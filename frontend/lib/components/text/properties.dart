import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import 'package:flutter/painting.dart'; // Needed for Alignment

class TextProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
      const StringProperty(
        key: 'content',
        displayName: 'Content',
        value: 'Sample Text',
        group: 'Text',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'fontSize',
        displayName: 'Font Size',
        value: 16,
        min: 0.0,
        max: 1000.0,
        group: 'Text',
        enable: Enabled(show: false, enabled: true),
      ),
      const ComponentColorProperty(
        key: 'color',
        displayName: 'Color',
        value: XDColor(
          ['#000000'],
          type: ColorType.solid,
          stops: [],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        enable: Enabled(show: true, enabled: true),
        group: 'Text',
      ),
      const StringProperty(
        key: 'fontFamily',
        displayName: 'Font Family',
        value: 'Roboto',
        group: 'Text',
        enable: Enabled(show: false, enabled: true),
      ),
      DropdownProperty<FontWeight>(
        key: 'fontWeight',
        displayName: 'Weight',
        value: FontWeight.normal,
        options: FontWeight.values,
        displayText: (dynamic fw) => fw.toString().split('.').last,
        group: 'Text',
        enable: const Enabled(show: false, enabled: true),
      ),
    ]);
  }

  static Map<String, String? Function(dynamic)> get validators => {
    'content': (value) => value is String ? null : 'content must be a string',
    'fontSize': (value) => value is num ? null : 'fontSize must be a number',
    'color': (value) {
      if (value is XDColor) return null;
      if (value is String && (value.startsWith('#') || value.startsWith('0x')))
        return null;
      if (value is Map && value.containsKey('value'))
        return null; // JSON structure for color
      return 'color must be a valid color (Hex string, XDColor, or JSON object)';
    },
    'fontFamily': (value) =>
        value is String ? null : 'fontFamily must be a string',
    'fontWeight': (value) => null, // Enum value, safe
  };
}
