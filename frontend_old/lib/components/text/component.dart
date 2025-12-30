import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../models/component_properties.dart';
import '../../models/enums.dart';
import '../../models/types/color.dart';
import '../component_properties_factory.dart';

class TextComponent extends ComponentModel {
  TextComponent({
    required super.id,
    required super.x,
    required super.y,
    ComponentProperties? properties,
    super.resizable = false, // Text components are typically not resizable
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
    
    // Convert FontWeight to numeric value for json_dynamic_widget
    int fontWeightValue = switch (fontWeight) {
      FontWeight.w100 => 100,
      FontWeight.w200 => 200,
      FontWeight.w300 => 300,
      FontWeight.w400 => 400,
      FontWeight.w500 => 500,
      FontWeight.w600 => 600,
      FontWeight.w700 => 700,
      FontWeight.w800 => 800,
      FontWeight.w900 => 900,
      _ => 400,
    };
    
    // Convert color to hex string format (RGB only, no alpha)
    final colorValue = color.toColor();
    final colorHex = '#${colorValue.red.toRadixString(16).padLeft(2, '0')}${colorValue.green.toRadixString(16).padLeft(2, '0')}${colorValue.blue.toRadixString(16).padLeft(2, '0')}';
    
    // Pure visual component - no interactions (handled by overlay layer)
    return {
      'type': 'text',
      'args': {
        'data': content,
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