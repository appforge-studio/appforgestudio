import '../models/component_properties.dart';
import '../models/enums.dart';
import 'container/properties.dart';
import 'text/properties.dart';
import 'image/properties.dart';

// Factory class to create default properties for each component type
class ComponentPropertiesFactory {
  // Get default properties for a component type
  static ComponentProperties getDefaultProperties(ComponentType type) {
    switch (type) {
      case ComponentType.container:
        return ContainerProperties.createDefault();
      case ComponentType.text:
        return TextProperties.createDefault();
      case ComponentType.image:
        return ImageProperties.createDefault();
    }
  }
}
