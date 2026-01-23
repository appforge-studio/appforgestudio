import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/property_editor_controller.dart';
import '../utilities/pallet.dart';

import '../models/common_property.dart';
import '../models/component_properties.dart';

import 'property_text_field.dart';

import 'property_color_field.dart';
import 'property_icon_field.dart';
import 'property_side_field.dart';
import 'property_shadow_editor.dart';
import 'property_background_blur_editor.dart';
import 'property_font_selector.dart';
import 'property_overlay_dropdown.dart';

class PropertyEditor extends StatelessWidget {
  const PropertyEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PropertyEditorController>();
    return Obx(() {
      // Always show container to maintain layout, but maybe empty or default text
      if (!controller.isVisible || controller.selectedComponent == null) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
          decoration: BoxDecoration(
            color: Pallet.inside1,
            borderRadius: BorderRadius.circular(20),
          ),
          width: 300,
          child: Center(
            child: Text(
              'Select a component',
              style: TextStyle(color: Pallet.font2, fontSize: 13),
            ),
          ),
        );
      }

      final component = controller.selectedComponent!;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
        decoration: BoxDecoration(
          color: Pallet.inside1,
          borderRadius: BorderRadius.circular(20),
        ),
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                "Properties",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Pallet.font1,
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Property fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
    // Filter out properties that are handled by specialized editors (like ShadowEditor)
    // The "shadow" boolean property is the trigger for the editor.
    final ignoredProperties = [
      'shadowColor',
      'shadowBlur',
      'shadowSpread',
      'shadowX',
      'shadowY',
      'backgroundBlurOpacity',
    ];

    final availableProperties = properties.properties.where((p) {
      if (ignoredProperties.contains(p.key)) return false;

      // Conditional visibility
      if (p.key == 'borderWidth') {
        return properties.shouldApplyProperty('border');
      }

      return true;
    }).toList();

    // Group properties
    final Map<String, List<Property>> groupedProperties = {};
    for (var property in availableProperties) {
      if (!groupedProperties.containsKey(property.group)) {
        groupedProperties[property.group] = [];
      }
      groupedProperties[property.group]!.add(property);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedProperties.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  color: Pallet.font2,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...entry.value.map((property) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFieldForProperty(property),
              );
            }),
            // Add a divider after each group
            Divider(color: Pallet.inside2, height: 1),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFieldForProperty(Property property) {
    if (property.key == 'shadow') {
      return PropertyShadowEditor(
        properties: properties, // Pass full properties to access siblings
        onChanged: onChanged,
      );
    }

    if (property.key == 'backgroundBlur') {
      return PropertyBackgroundBlurEditor(
        properties: properties, // Pass full properties to access siblings
        onChanged: onChanged,
      );
    }

    if (property.key == 'fontFamily') {
      return _buildFontField(property as StringProperty);
    }

    if (property.key == 'fontWeight') {
      return _buildWeightField(property as DropdownProperty);
    }

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
      case PropertyType.icon:
        return _buildIconField(property as IconProperty);
      default:
        return Text('Unsupported property type: ${property.type}');
    }
  }

  Widget _buildPropertyRow({
    required Property property,
    required Widget child,
    bool showLabel = true,
    bool expandField = true,
  }) {
    // If property acts as a section or special type, might handle differently.
    // For now, standard layout: Label (80px) -> Checkbox (if enabled) -> Input (Expanded)

    // Checkbox logic
    Widget? checkbox;
    if (property.enable.show) {
      checkbox = Padding(
        padding: const EdgeInsets.only(right: 5),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: property.enable.enabled,
            onChanged: (bool? value) {
              if (value != null) {
                _updateEnable(property.key, value);
              }
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: Pallet.inside3,
            checkColor: Colors.white,
            side: BorderSide(color: Pallet.font2, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }

    // Logic for layout:
    // If expandField is true: Label -> Checkbox -> Expanded(Child)
    // If expandField is false: Label -> Spacer -> Checkbox -> Child (Child must have size)

    if (expandField) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLabel)
            SizedBox(
              width: 80,
              child: Text(
                "${property.displayName}:",
                style: TextStyle(fontSize: 13, color: Pallet.font1),
              ),
            ),

          if (checkbox != null) checkbox,

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
    } else {
      // Right aligned (fixed width child)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLabel)
            SizedBox(
              width: 80,
              child: Text(
                "${property.displayName}:",
                style: TextStyle(fontSize: 13, color: Pallet.font1),
              ),
            ),

          const Spacer(), // Pushes Checkbox + Child to right

          if (checkbox != null) checkbox,

          Opacity(
            opacity: property.enable.enabled ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !property.enable.enabled,
              child: child,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStringField(StringProperty property) {
    return _buildPropertyRow(
      property: property,
      child: PropertyTextField(
        label: property.displayName,
        value: property.value,
        onChanged: (value) => _updateValue(property.key, value),
        showLabel: false,
      ),
    );
  }

  Widget _buildNumberField(NumberProperty property) {
    return _buildPropertyRow(
      property: property,
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
        showLabel: false,
        width: 60,
      ),
      expandField: false,
    );
  }

  Widget _buildColorField(ComponentColorProperty property) {
    return _buildPropertyRow(
      property: property,
      child: PropertyColorField(
        label: property.displayName,
        value: property.value,
        onChanged: (newValue) => _updateValue(property.key, newValue),
        showLabel: false,
        width: 30, // Square shape
      ),
      expandField: false,
    );
  }

  Widget _buildBooleanField(BooleanProperty property) {
    // For boolean, simpler to just show Checkbox -> Switch?
    // Or keep Label -> Checkbox -> Switch.
    return _buildPropertyRow(
      property: property,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Switch(
          value: property.value,
          onChanged: (value) => _updateValue(property.key, value),
        ),
      ),
    );
  }

  Widget _buildDropdownField(DropdownProperty property) {
    return _buildPropertyRow(
      property: property,
      child: DropdownButtonFormField<dynamic>(
        value: property.value,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Pallet.inside2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: property.options.map<DropdownMenuItem<dynamic>>((option) {
          return DropdownMenuItem<dynamic>(
            value: option,
            child: Text(
              property.displayText(option),
              style: TextStyle(fontSize: 12, color: Pallet.font1),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            _updateValue(property.key, newValue);
          }
        },
        style: TextStyle(fontSize: 12, color: Pallet.font1),
        dropdownColor: Pallet.inside1,
      ),
    );
  }

  Widget _buildSideField(SideProperty property) {
    List<String>? labels;
    if (property.key == 'borderRadius') {
      labels = ['tl', 'tr', 'br', 'bl'];
    }

    return _buildPropertyRow(
      property: property,
      child: PropertySideField(
        label: property.displayName,
        value: property.value,
        onChanged: (newValue) => _updateValue(property.key, newValue),
        labels: labels,
        showLabel: false,
      ),
    );
  }

  Widget _buildIconField(IconProperty property) {
    return _buildPropertyRow(
      property: property,
      child: PropertyIconField(
        label: property.displayName,
        value: property.value,
        onChanged: (newValue) => _updateValue(property.key, newValue),
        showLabel: false,
      ),
    );
  }

  Widget _buildFontField(StringProperty property) {
    return _buildPropertyRow(
      property: property,
      child: SizedBox(
        width: 120,
        child: PropertyFontSelector(
          label: property.displayName,
          value: property.value,
          onChanged: (newValue) => _updateValue(property.key, newValue),
          showLabel: false,
        ),
      ),
      expandField: false,
    );
  }

  Widget _buildWeightField(DropdownProperty property) {
    return _buildPropertyRow(
      property: property,
      child: SizedBox(
        width: 100,
        child: PropertyOverlayDropdown(
          value: property.value,
          items: property.options,
          onChanged: (newValue) {
            _updateValue(property.key, newValue);
          },
          showLabel: false,
          itemLabelBuilder: (val) => property.displayText(val),
        ),
      ),
      expandField: false,
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
