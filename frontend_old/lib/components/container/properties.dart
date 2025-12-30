import '../../models/common_property.dart';
import '../../models/component_properties.dart';
import '../../models/types/color.dart';
import '../../models/types/side.dart';

class ContainerProperties {
  static ComponentProperties createDefault() {
    return ComponentProperties([
      const NumberProperty(
        key: 'width',
        displayName: 'Width',
        value: 100.0,
        min: 10.0,
        max: 500.0,
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'height',
        displayName: 'Height',
        value: 100.0,
        min: 10.0,
        max: 500.0,
        enable: Enabled(show: true, enabled: true),
      ),
      ComponentColorProperty(
        key: 'backgroundColor',
        displayName: 'Background Color',
        value: XDColor(['#FFFFFF']), // White color
        enable: Enabled(show: true, enabled: true),
      ),
      const NumberProperty(
        key: 'borderRadius',
        displayName: 'Border Radius',
        value: 0.0,
        min: 0.0,
        max: 50.0,
        enable: Enabled(show: true, enabled: true),
      ),
      SideProperty(
        key: 'padding',
        displayName: 'Padding',
        value: XDSide.all(0.0),
        enable: Enabled(show: true, enabled: true),
      ),
    ]);
  }
}
