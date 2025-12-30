import '../models/component_model.dart';
import '../models/component_properties.dart';
{{IMPORTS}}

enum ComponentType { {{COMPONENT_TYPE_ENUM}} }

class ComponentFactory {
  static ComponentModel createComponent(
    ComponentType type,
    double x,
    double y, {
    String? id,
  }) {
    final componentId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

    switch (type) {
{{CASES_CREATE_COMPONENT}}
    }
  }

  static ComponentModel fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = ComponentType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => throw ArgumentError('Unknown component type: $typeString'),
    );

    switch (type) {
{{CASES_FROM_JSON}}
    }
  }

  static Map<String, dynamic> toJsonSchema(ComponentModel component) {
    return component.jsonSchema;
  }

  // Additional utility methods for creating default property instances
{{UTILITY_METHODS}}

  // Method to get default properties for a component type
  static ComponentProperties getDefaultPropertiesForType(ComponentType type) {
    switch (type) {
{{CASES_GET_DEFAULT_PROPERTIES}}
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
{{CASES_CREATE_WITH_PROPERTIES}}
    }
  }
}
