import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart';
import '../component_factory.dart';
import '../component_properties_factory.dart';

class TextComponent extends ComponentModel {
  TextComponent({
    required super.id,
    required super.x,
    required super.y,
    ComponentProperties? properties,
    super.resizable = false,
  }) : super(
          type: ComponentType.text,
          properties: properties ?? ComponentPropertiesFactory.getDefaultProperties(ComponentType.text),
        );
  
  @override
  Map<String, dynamic> get jsonSchema {
    final content = properties.getProperty<String>('content') ?? 'Sample Text';
    final fontSize = properties.getProperty<double>('fontSize') ?? 16.0;
    final color = properties.getProperty<XDColor>('color') ?? XDColor(['#000000']);
    final alignment = properties.getProperty<TextAlign>('alignment') ?? TextAlign.left;
    final fontWeight = properties.getProperty<FontWeight>('fontWeight') ?? FontWeight.normal;
    final fontFamily = properties.getProperty<String>('fontFamily') ?? 'Roboto';
    
    // Convert TextAlign enum to string for json_dynamic_widget
    String textAlignString = switch (alignment) {
      TextAlign.left => 'left',
      TextAlign.right => 'right', 
      TextAlign.center => 'center',
      TextAlign.justify => 'justify',
      TextAlign.start => 'start',
      TextAlign.end => 'end',
    };
    
    // Convert FontWeight to string value for json_dynamic_widget
    String fontWeightValue = switch (fontWeight) {
      FontWeight.w100 => 'w100',
      FontWeight.w200 => 'w200',
      FontWeight.w300 => 'w300',
      FontWeight.w400 => 'w400',
      FontWeight.w500 => 'w500',
      FontWeight.w600 => 'w600',
      FontWeight.w700 => 'w700',
      FontWeight.w800 => 'w800',
      FontWeight.w900 => 'w900',
      _ => 'w400',
    };
    
    // Convert color to 8-digit hex string format (ARGB)
    final colorValue = color.toColor();
    final colorHex = '#${colorValue.toARGB32().toRadixString(16).padLeft(8, '0')}';
    
    // Pure visual component - no interactions (handled by overlay layer)
    return {
      'type': 'text',
      'args': {
        'text': content,
        'style': {
          'fontSize': fontSize,
          'color': colorHex.toUpperCase(),
          'fontWeight': fontWeightValue,
          'fontFamily': fontFamily,
        },
        'textAlign': textAlignString,
      },
    };
  }
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'x': x,
    'y': y,
    'properties': properties.toJson(),
    'resizable': resizable,
  };
  
  @override
  TextComponent copyWith({double? x, double? y, ComponentProperties? properties, bool? resizable}) {
    return TextComponent(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      properties: properties ?? this.properties,
      resizable: resizable ?? this.resizable,
    );
  }
  
  factory TextComponent.fromJson(Map<String, dynamic> json) {
    final defaultProperties = ComponentPropertiesFactory.getDefaultProperties(ComponentType.text);
    final properties = defaultProperties.fromJson(json['properties'] ?? {});
    
    return TextComponent(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      properties: properties,
      resizable: json['resizable'] as bool? ?? false,
    );
  }
}
