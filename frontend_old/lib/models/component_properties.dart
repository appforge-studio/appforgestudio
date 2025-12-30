import 'common_property.dart';

// Base component properties class that all components use
class ComponentProperties {
  final List<Property> _properties;

  ComponentProperties(this._properties);

  // Get all properties
  List<Property> get properties => List.unmodifiable(_properties);

  // Get property by key
  T? getProperty<T>(String key) {
    try {
      final property = _properties.firstWhere((p) => p.key == key);
      return property.value as T?;
    } catch (e) {
      return null;
    }
  }

  // Update property by key
  ComponentProperties updateProperty(String key, dynamic value) {
    final updatedProperties = _properties.map((property) {
      if (property.key == key) {
        return property.copyWith(value: value);
      }
      return property;
    }).toList();

    return ComponentProperties(updatedProperties);
  }

  // Check if property is enabled
  bool isPropertyEnabled(String key) {
    try {
      final property = _properties.firstWhere((p) => p.key == key);
      return property.enable.enabled;
    } catch (e) {
      return false; // Default to false if not found? Or true? Usually properties without enable flag are considered always enabled, but here properties have explicit Enabled object.
      // Wait, Property defaults enable to false/false.
      // If a property is not supposed to be toggleable, enable.show is false.
      // If enable.show is false, we should treat it as "not toggleable", so effectively "enabled" (always applied) OR "disabled" (never applied)?
      // Actually, if show is false, it behaves like a normal property, so it should be considered "enabled" for rendering purposes usually, unless the logic is "if (enable.show && !enable.enabled) skip".
      // Let's safe guard:
    }
  }

  // Helper to check if we should apply the property
  bool shouldApplyProperty(String key) {
    try {
      final property = _properties.firstWhere((p) => p.key == key);
      // If toggle is not shown, it's always enabled (or effectively true).
      // If toggle IS shown, we respect the enabled flag.
      if (!property.enable.show) return true;
      return property.enable.enabled;
    } catch (e) {
      return true;
    }
  }

  // Update property enabled state
  ComponentProperties updatePropertyEnabled(String key, bool enabled) {
    final updatedProperties = _properties.map((property) {
      if (property.key == key) {
        return property.copyWith(
          enable: property.enable.copyWith(enabled: enabled),
        );
      }
      return property;
    }).toList();

    return ComponentProperties(updatedProperties);
  }

  // Convert all properties to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    for (final property in _properties) {
      json[property.key] = property.toJson();
    }
    return json;
  }

  // Create properties from JSON
  ComponentProperties fromJson(Map<String, dynamic> json) {
    final updatedProperties = _properties.map((property) {
      final jsonValue = json[property.key];
      if (jsonValue != null) {
        return property.fromJson(jsonValue);
      }
      return property;
    }).toList();

    return ComponentProperties(updatedProperties);
  }

  // Create a copy with updated properties
  ComponentProperties copyWith(List<Property>? properties) {
    return ComponentProperties(properties ?? _properties);
  }
}
