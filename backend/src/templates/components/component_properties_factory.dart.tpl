import 'component_factory.dart';

import '../models/component_properties.dart';
{{IMPORTS}}

// Factory class to create default properties for each component type
class ComponentPropertiesFactory {
  // Get default properties for a component type
  static ComponentProperties getDefaultProperties(ComponentType type) {
    switch (type) {
      {{CASES_GET_DEFAULT_PROPERTIES}}
    }
  }

  static Map<String, String? Function(dynamic)> getValidators(ComponentType type) {
    switch (type) {
{{CASES_GET_VALIDATORS}}
    }
  }
}
