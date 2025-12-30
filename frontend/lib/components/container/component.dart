import '../../models/component_model.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart';
import '../../models/types/side.dart';
import '../component_factory.dart';
import '../component_properties_factory.dart';

class ContainerComponent extends ComponentModel {
  ContainerComponent({
    required super.id,
    required super.x,
    required super.y,
    ComponentProperties? properties,
    super.resizable = true,
  }) : super(
         type: ComponentType.container,
         properties:
             properties ??
             ComponentPropertiesFactory.getDefaultProperties(
               ComponentType.container,
             ),
       );

  @override
  Map<String, dynamic> get jsonSchema {
    final width = properties.shouldApplyProperty('width')
        ? properties.getProperty<double>('width')
        : null;
    final height = properties.shouldApplyProperty('height')
        ? properties.getProperty<double>('height')
        : null;

    final applyBg = properties.shouldApplyProperty('backgroundColor');
    final backgroundColor =
        properties.getProperty<XDColor>('backgroundColor') ??
        XDColor(['#FFFFFF']);

    // Convert color to hex string format
    String? colorHex;
    if (applyBg) {
      colorHex =
          '#${backgroundColor.toColor().toARGB32().toRadixString(16).padLeft(8, '0')}';
    }

    final borderRadius = properties.shouldApplyProperty('borderRadius')
        ? (properties.getProperty<double>('borderRadius') ?? 8.0)
        : 0.0;

    final applyPadding = properties.shouldApplyProperty('padding');
    final padding = applyPadding
        ? (properties.getProperty<XDSide>('padding') ?? XDSide.all(8.0))
        : null;

    // Pure visual component - no interactions (handled by overlay layer)
    return {
      'type': 'container',
      'args': {
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'decoration': {
          if (colorHex != null) 'color': colorHex.toUpperCase(),
          'borderRadius': {'radius': borderRadius, 'type': 'circular'},
        },
        if (padding != null) 'padding': padding.left,
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
  ContainerComponent copyWith({
    double? x,
    double? y,
    ComponentProperties? properties,
    bool? resizable,
  }) {
    return ContainerComponent(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      properties: properties ?? this.properties,
      resizable: resizable ?? this.resizable,
    );
  }

  factory ContainerComponent.fromJson(Map<String, dynamic> json) {
    final defaultProperties = ComponentPropertiesFactory.getDefaultProperties(
      ComponentType.container,
    );
    final properties = defaultProperties.fromJson(json['properties'] ?? {});

    return ContainerComponent(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      properties: properties,
      resizable: json['resizable'] as bool? ?? true,
    );
  }
}
