import '../../models/component_model.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart';
import '../../models/types/side.dart';
import '../component_properties_factory.dart';
import '../component_factory.dart'; // Import for ComponentType
import 'package:flutter/material.dart';

class {{CLASS_NAME}}Component extends ComponentModel {
  {{CLASS_NAME}}Component({
    required super.id,
    required super.x,
    required super.y,
    ComponentProperties? properties,
    super.resizable = {{IS_RESIZABLE}},
  }) : super(
         type: ComponentType.{{COMPONENT_NAME}},
         properties:
             properties ??
             ComponentPropertiesFactory.getDefaultProperties(
               ComponentType.{{COMPONENT_NAME}},
             ),
       );

  @override
  Map<String, dynamic> get jsonSchema {
    return {
      'type': '{{COMPONENT_NAME}}',
      'args': {},
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
  {{CLASS_NAME}}Component copyWith({
    double? x,
    double? y,
    ComponentProperties? properties,
    bool? resizable,
  }) {
    return {{CLASS_NAME}}Component(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      properties: properties ?? this.properties,
      resizable: resizable ?? this.resizable,
    );
  }

  factory {{CLASS_NAME}}Component.fromJson(Map<String, dynamic> json) {
    final defaultProperties = ComponentPropertiesFactory.getDefaultProperties(
      ComponentType.{{COMPONENT_NAME}},
    );
    final properties = defaultProperties.fromJson(json['properties'] ?? {});

    return {{CLASS_NAME}}Component(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      properties: properties,
      resizable: json['resizable'] as bool? ?? true,
    );
  }
}
