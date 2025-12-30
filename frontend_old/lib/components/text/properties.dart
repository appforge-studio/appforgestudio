import 'package:flutter/material.dart';
import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart';

class TextProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
      const StringProperty(
        key: 'content',
        displayName: 'Text Content',
        value: 'Sample Text',
      ),
      const NumberProperty(
        key: 'fontSize',
        displayName: 'Font Size',
        value: 16.0,
        min: 8.0,
        max: 72.0,
      ),
      ComponentColorProperty(
        key: 'color',
        displayName: 'Text Color',
        value: XDColor(['#000000']), // Black color
      ),
      DropdownProperty<TextAlign>(
        key: 'alignment',
        displayName: 'Text Alignment',
        value: TextAlign.left,
        options: TextAlign.values,
        displayText: (align) => align.name,
      ),
      DropdownProperty<FontWeight>(
        key: 'fontWeight',
        displayName: 'Font Weight',
        value: FontWeight.normal,
        options: [
          FontWeight.w100,
          FontWeight.w200,
          FontWeight.w300,
          FontWeight.normal,
          FontWeight.w500,
          FontWeight.w600,
          FontWeight.bold,
          FontWeight.w800,
          FontWeight.w900,
        ],
        displayText: (weight) => weight.toString().split('.').last,
      ),
      const StringProperty(
        key: 'fontFamily',
        displayName: 'Font Family',
        value: 'Roboto',
      ),
    ]);
  }
}