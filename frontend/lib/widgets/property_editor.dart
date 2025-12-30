import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/property_editor_controller.dart';

import '../models/common_property.dart';
import '../models/component_properties.dart';
import '../models/types/side.dart';
import 'property_text_field.dart';

import 'property_color_field.dart';

class EnablePropertyWrapper extends StatelessWidget {
  final Property property;
  final Widget child;
  final Function(bool) onEnableChanged;

  const EnablePropertyWrapper({
    super.key,
    required this.property,
    required this.child,
    required this.onEnableChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!property.enable.show) return child;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Checkbox(
            value: property.enable.enabled,
            onChanged: (bool? value) {
              if (value != null) {
                onEnableChanged(value);
              }
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Opacity(
            opacity: property.enable.enabled ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !property.enable.enabled,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class PropertyEditor extends StatelessWidget {
  const PropertyEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PropertyEditorController>();
    return Obx(() {
      if (!controller.isVisible || controller.selectedComponent == null) {
        return Container(
          width: 300,
          color: Colors.grey[100],
          child: const Center(
            child: Text(
              'Select a component to edit properties',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        );
      }

      final component = controller.selectedComponent!;

      return Container(
        width: 300,
        color: Colors.grey[100],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  // Icon removed or can be generic if needed, using component name
                  const Icon(Icons.tune, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${component.type.name.toUpperCase()} Properties',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Property fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GenericPropertyEditor(
                  properties: component.properties,
                  onChanged: (newProperties) {
                    controller.updateComponentProperties(
                      component,
                      newProperties,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GenericPropertyEditor extends StatelessWidget {
  final ComponentProperties properties;
  final Function(ComponentProperties) onChanged;

  const GenericPropertyEditor({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: properties.properties.map((property) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFieldForProperty(property),
        );
      }).toList(),
    );
  }

  Widget _buildFieldForProperty(Property property) {
    switch (property.type) {
      case PropertyType.string:
        return _buildStringField(property as StringProperty);
      case PropertyType.number:
        return _buildNumberField(property as NumberProperty);
      case PropertyType.color:
        return _buildColorField(property as ComponentColorProperty);
      case PropertyType.boolean:
        return _buildBooleanField(property as BooleanProperty);
      case PropertyType.dropdown:
        return _buildDropdownField(property as DropdownProperty);
      case PropertyType.side:
        return _buildSideField(property as SideProperty);
      default:
        return Text('Unsupported property type: ${property.type}');
    }
  }

  Widget _buildStringField(StringProperty property) {
    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: PropertyTextField(
        label: property.displayName,
        value: property.value,
        onChanged: (value) => _updateValue(property.key, value),
      ),
    );
  }

  Widget _buildNumberField(NumberProperty property) {
    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: PropertyTextField(
        label: property.displayName,
        value: property.value.toString(),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final numValue = double.tryParse(value);
          if (numValue != null) {
            _updateValue(property.key, numValue);
          }
        },
      ),
    );
  }

  Widget _buildColorField(ComponentColorProperty property) {
    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: PropertyColorField(
        label: property.displayName,
        value: property.value,
        onChanged: (newValue) => _updateValue(property.key, newValue),
      ),
    );
  }

  Widget _buildBooleanField(BooleanProperty property) {
    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: Row(
        children: [
          Text(property.displayName, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Switch(
            value: property.value,
            onChanged: (value) => _updateValue(property.key, value),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(DropdownProperty property) {
    // DropdownProperty is generic, but we treat it as dynamic here for UI building
    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.displayName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<dynamic>(
            value: property.value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: property.options.map<DropdownMenuItem<dynamic>>((option) {
              return DropdownMenuItem<dynamic>(
                value: option,
                child: Text(property.displayText(option)),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                _updateValue(property.key, newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSideField(SideProperty property) {
    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: PropertyTextField(
        label: property.displayName,
        value: property.value.values.first.toString(),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final numValue = double.tryParse(value);
          if (numValue != null) {
            // For simplicity, we'll update all sides with the same value
            final newSide = XDSide.all(numValue);
            _updateValue(property.key, newSide);
          }
        },
      ),
    );
  }

  void _updateValue(String key, dynamic value) {
    final updated = properties.updateProperty(key, value);
    onChanged(updated);
  }

  void _updateEnable(String key, bool enabled) {
    final updated = properties.updatePropertyEnabled(key, enabled);
    onChanged(updated);
  }
}
