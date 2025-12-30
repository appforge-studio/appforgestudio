import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../models/component_properties.dart';
import '../../models/enums.dart';
import '../component_properties_factory.dart';

class ImageComponent extends ComponentModel {
  ImageComponent({
    required super.id,
    required super.x,
    required super.y,
    ComponentProperties? properties,
    super.resizable = true, // Images are typically resizable
  }) : super(
          type: ComponentType.image,
          properties: properties ?? ComponentPropertiesFactory.getDefaultProperties(ComponentType.image),
        );
  
  @override
  Map<String, dynamic> get jsonSchema {
    final source = properties.getProperty<String>('source') ?? 'https://via.placeholder.com/150';
    final width = properties.getProperty<double>('width') ?? 150.0;
    final height = properties.getProperty<double>('height') ?? 150.0;
    final fit = properties.getProperty<BoxFit>('fit') ?? BoxFit.cover;
    
    // Convert BoxFit enum to string
    String boxFitString = switch (fit) {
      BoxFit.fill => 'fill',
      BoxFit.contain => 'contain',
      BoxFit.cover => 'cover',
      BoxFit.fitWidth => 'fitWidth',
      BoxFit.fitHeight => 'fitHeight',
      BoxFit.none => 'none',
      BoxFit.scaleDown => 'scaleDown',
    };
    
    // Pure visual component - no interactions (handled by overlay layer)
    return {
      'type': 'image',
      'args': {
        'image': source,
        'width': width,
        'height': height,
        'fit': boxFitString,
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
  ImageComponent copyWith({double? x, double? y, ComponentProperties? properties, bool? resizable}) {
    return ImageComponent(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      properties: properties ?? this.properties,
      resizable: resizable ?? this.resizable,
    );
  }
  
  factory ImageComponent.fromJson(Map<String, dynamic> json) {
    final defaultProperties = ComponentPropertiesFactory.getDefaultProperties(ComponentType.image);
    final properties = defaultProperties.fromJson(json['properties'] ?? {});
    
    return ImageComponent(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      properties: properties,
      resizable: json['resizable'] as bool? ?? true,
    );
  }
}