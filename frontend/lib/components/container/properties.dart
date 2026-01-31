import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import '../../models/types/corner.dart';
import 'package:flutter/painting.dart'; // Needed for Alignment

class ContainerProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
      const NumberProperty(
        key: 'width',
        displayName: 'Width',
        value: 100,
        min: 0.0,
        max: 1000.0,
        group: 'Layout',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'height',
        displayName: 'Height',
        value: 100,
        min: 0.0,
        max: 1000.0,
        group: 'Layout',
        enable: Enabled(show: true, enabled: true),
      ),
      const ComponentColorProperty(
        key: 'backgroundColor',
        displayName: 'Color',
        value: XDColor(
          ['#FFFFFF'],
          type: ColorType.solid,
          stops: [],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        enable: Enabled(show: true, enabled: true),
        group: 'Appearance',
      ),
      const ComponentColorProperty(
        key: 'border',
        displayName: 'Border',
        value: XDColor(
          ['#000000'],
          type: ColorType.solid,
          stops: [],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        enable: Enabled(show: true, enabled: false),
        group: 'Appearance',
      ),
      const NumberProperty(
        key: 'borderWidth',
        displayName: 'Border Width',
        value: 1,
        min: 0.0,
        max: 1000.0,
        group: 'Appearance',
        enable: Enabled(show: false, enabled: true),
      ),
      CornerProperty(
        key: 'borderRadius',
        displayName: 'Radius',
        value: XDCorner.all(0),
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
      const BooleanProperty(
        key: 'shadow',
        displayName: 'Shadow',
        value: false,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
      const ComponentColorProperty(
        key: 'shadowColor',
        displayName: 'Shadow Color',
        value: XDColor(
          ['#33000000'],
          type: ColorType.solid,
          stops: [],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        enable: Enabled(show: true, enabled: true),
        group: 'Appearance',
      ),
      const NumberProperty(
        key: 'shadowBlur',
        displayName: 'Blur',
        value: 8,
        min: 0.0,
        max: 1000.0,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'shadowSpread',
        displayName: 'Spread',
        value: 0,
        min: 0.0,
        max: 1000.0,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'shadowX',
        displayName: 'X',
        value: 0,
        min: 0.0,
        max: 1000.0,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'shadowY',
        displayName: 'Y',
        value: 4,
        min: 0.0,
        max: 1000.0,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'backgroundBlur',
        displayName: 'Background Blur',
        value: 0,
        min: 0.0,
        max: 1000.0,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'backgroundBlurOpacity',
        displayName: 'Background Blur Opacity',
        value: 1.0,
        min: 0.0,
        max: 1.0,
        group: 'Appearance',
        enable: Enabled(show: true, enabled: true),
      ),
    ]);
  }

  static Map<String, String? Function(dynamic)> get validators => {
    'width': (value) => value is num ? null : 'width must be a number',
    'height': (value) => value is num ? null : 'height must be a number',
    'backgroundColor': (value) {
      if (value is XDColor) return null;
      if (value is String && (value.startsWith('#') || value.startsWith('0x')))
        return null;
      if (value is Map && value.containsKey('value'))
        return null; // JSON structure for color
      return 'backgroundColor must be a valid color (Hex string, XDColor, or JSON object)';
    },
    'border': (value) {
      if (value is XDColor) return null;
      if (value is String && (value.startsWith('#') || value.startsWith('0x')))
        return null;
      if (value is Map && value.containsKey('value'))
        return null; // JSON structure for color
      return 'border must be a valid color (Hex string, XDColor, or JSON object)';
    },
    'borderWidth': (value) =>
        value is num ? null : 'borderWidth must be a number',
    'borderRadius': (value) =>
        value is XDCorner ? null : 'borderRadius must be an XDCorner',
    'shadow': (value) => value is bool ? null : 'shadow must be a boolean',
    'shadowColor': (value) {
      if (value is XDColor) return null;
      if (value is String && (value.startsWith('#') || value.startsWith('0x')))
        return null;
      if (value is Map && value.containsKey('value'))
        return null; // JSON structure for color
      return 'shadowColor must be a valid color (Hex string, XDColor, or JSON object)';
    },
    'shadowBlur': (value) =>
        value is num ? null : 'shadowBlur must be a number',
    'shadowSpread': (value) =>
        value is num ? null : 'shadowSpread must be a number',
    'shadowX': (value) => value is num ? null : 'shadowX must be a number',
    'shadowY': (value) => value is num ? null : 'shadowY must be a number',
    'backgroundBlur': (value) =>
        value is num ? null : 'backgroundBlur must be a number',
    'backgroundBlurOpacity': (value) =>
        value is num ? null : 'backgroundBlurOpacity must be a number',
  };
}
