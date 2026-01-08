import '../models/component_model.dart';
import '../models/component_properties.dart';
import '../components/container/component.dart';
import '../components/container/properties.dart';
import '../components/icon/component.dart';
import '../components/icon/properties.dart';
import '../components/image/component.dart';
import '../components/image/properties.dart';
import '../components/text/component.dart';
import '../components/text/properties.dart';

enum ComponentType { container, icon, image, text }

class ComponentFactory {
  static ComponentModel createComponent(
    ComponentType type,
    double x,
    double y, {
    String? id,
  }) {
    final componentId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

    switch (type) {
      case ComponentType.container:
        return ContainerComponent(id: componentId, x: x, y: y);
      case ComponentType.icon:
        return IconComponent(id: componentId, x: x, y: y);
      case ComponentType.image:
        return ImageComponent(id: componentId, x: x, y: y);
      case ComponentType.text:
        return TextComponent(id: componentId, x: x, y: y);
    }
  }

  static ComponentModel fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = ComponentType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => throw ArgumentError('Unknown component type: $typeString'),
    );

    switch (type) {
      case ComponentType.container:
        return ContainerComponent.fromJson(json);
      case ComponentType.icon:
        return IconComponent.fromJson(json);
      case ComponentType.image:
        return ImageComponent.fromJson(json);
      case ComponentType.text:
        return TextComponent.fromJson(json);
    }
  }

  static Map<String, dynamic> toJsonSchema(ComponentModel component) {
    return component.jsonSchema;
  }

  // Additional utility methods for creating default property instances
  static ComponentProperties createDefaultContainerProperties() {
    return ContainerProperties.createDefault();
  }

  static ComponentProperties createDefaultIconProperties() {
    return IconProperties.createDefault();
  }

  static ComponentProperties createDefaultImageProperties() {
    return ImageProperties.createDefault();
  }

  static ComponentProperties createDefaultTextProperties() {
    return TextProperties.createDefault();
  }

  // Method to get default properties for a component type
  static ComponentProperties getDefaultPropertiesForType(ComponentType type) {
    switch (type) {
      case ComponentType.container:
        return createDefaultContainerProperties();
      case ComponentType.icon:
        return createDefaultIconProperties();
      case ComponentType.image:
        return createDefaultImageProperties();
      case ComponentType.text:
        return createDefaultTextProperties();
    }
  }

  // Method to create component with custom properties
  static ComponentModel createComponentWithProperties(
    ComponentType type,
    double x,
    double y,
    ComponentProperties properties, {
    String? id,
  }) {
    final componentId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

    switch (type) {
      case ComponentType.container:
        return ContainerComponent(
          id: componentId,
          x: x,
          y: y,
          properties: properties,
        );
      case ComponentType.icon:
        return IconComponent(
          id: componentId,
          x: x,
          y: y,
          properties: properties,
        );
      case ComponentType.image:
        return ImageComponent(
          id: componentId,
          x: x,
          y: y,
          properties: properties,
        );
      case ComponentType.text:
        return TextComponent(
          id: componentId,
          x: x,
          y: y,
          properties: properties,
        );
    }
  }
}
