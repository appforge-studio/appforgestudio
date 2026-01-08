import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart';
import '../component_factory.dart';
import '../component_properties_factory.dart';

class IconComponent extends ComponentModel {
  IconComponent({
    required super.id,
    required super.x,
    required super.y,
    ComponentProperties? properties,
    super.resizable = false,
  }) : super(
         type: ComponentType.icon,
         properties:
             properties ??
             ComponentPropertiesFactory.getDefaultProperties(
               ComponentType.icon,
             ),
       );

  factory IconComponent.fromJson(Map<String, dynamic> json) {
    final defaultProperties = ComponentPropertiesFactory.getDefaultProperties(
      ComponentType.icon,
    );
    final properties = defaultProperties.fromJson(json['properties'] ?? {});

    return IconComponent(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      properties: properties,
      resizable: json['resizable'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'x': x,
      'y': y,
      'properties': properties.toJson(),
      'resizable': resizable,
    };
  }

  @override
  IconComponent copyWith({
    double? x,
    double? y,
    ComponentProperties? properties,
    bool? resizable,
  }) {
    return IconComponent(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      properties: properties ?? this.properties,
      resizable: resizable ?? this.resizable,
    );
  }

  @override
  Map<String, dynamic> get jsonSchema {
    final iconProp = properties.getProperty<String>('icon');
    final icon = iconProp ?? '';

    final colorProp = properties.getProperty<XDColor>('color');
    final c = colorProp?.toColor() ?? const Color(0xFF000000);
    // Hex string #AARRGGBB
    final colorHex = '#${c.toARGB32().toRadixString(16).padLeft(8, '0')}';

    final size = properties.getProperty<num>('size')?.toDouble() ?? 24.0;

    return {
      'type': 'svg',
      'args': {'data': icon, 'color': colorHex, 'width': size, 'height': size},
    };
  }
}

// Add extension to help with null check
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
