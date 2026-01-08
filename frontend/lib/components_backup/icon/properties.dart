import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import 'package:flutter/painting.dart'; // Needed for Alignment

class IconProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
            const IconProperty(
            key: 'icon',
            displayName: 'icon',
            value: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><!--! Font Awesome Free 7.1.0 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) Copyright 2025 Fonticons, Inc. --><path fill="currentColor" d="M277.8 8.6c-12.3-11.4-31.3-11.4-43.5 0l-224 208c-9.6 9-12.8 22.9-8 35.1S18.8 272 32 272l16 0 0 176c0 35.3 28.7 64 64 64l288 0c35.3 0 64-28.7 64-64l0-176 16 0c13.2 0 25-8.1 29.8-20.3s1.6-26.2-8-35.1l-224-208zM240 320l32 0c26.5 0 48 21.5 48 48l0 96-128 0 0-96c0-26.5 21.5-48 48-48z"/></svg>',
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
      const NumberProperty(
        key: 'size',
        displayName: 'size',
        value: 24,
        min: 0.0,
        max: 1000.0,
        enable: Enabled(show: true, enabled: true),
      ),
    ]);
  }
}
