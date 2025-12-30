import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart'; // Needed for XDColor
import 'package:flutter/painting.dart'; // Needed for Alignment

class {{CLASS_NAME}}Properties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
      {{PROPERTIES_CODE}}
    ]);
  }
}
