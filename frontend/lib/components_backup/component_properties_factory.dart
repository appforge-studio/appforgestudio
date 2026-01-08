import 'component_factory.dart';

import '../models/component_properties.dart';
import 'container/properties.dart';
import 'icon/properties.dart';
import 'image/properties.dart';
import 'text/properties.dart';

// Factory class to create default properties for each component type
class ComponentPropertiesFactory {
  // Get default properties for a component type
  static ComponentProperties getDefaultProperties(ComponentType type) {
    switch (type) {
      case ComponentType.container:
        return ContainerProperties.createDefault();
      case ComponentType.icon:
        return IconProperties.createDefault();
      case ComponentType.image:
        return ImageProperties.createDefault();
      case ComponentType.text:
        return TextProperties.createDefault();
    }
  }
}
