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
            activeColor: Pallet.inside3,
            checkColor: Colors.white,
            side: BorderSide(color: Pallet.font2),
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
            // Header Actions
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 10),
                children: [
                  _buildHeaderAction(
                    icon: Icons.question_mark,
                    label: "Condition",
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  _buildHeaderAction(
                    icon: Icons.delete,
                    label: "Delete",
                    color: Colors.red,
                    onTap: () {
                      // Implement delete logic later
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Property fields
            Expanded(
              child: SingleChildScrollView(
                // padding: const EdgeInsets.all(16),
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

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Pallet.inside1,
          border: Border.all(color: Pallet.inside2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Pallet.font1)),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
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
      case PropertyType.icon:
        return _buildIconField(property as IconProperty);
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
    List<String>? labels;
    if (property.key == 'borderRadius') {
      labels = ['tl', 'tr', 'br', 'bl'];
    }

    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: PropertySideField(
        label: property.displayName,
        value: property.value,
        onChanged: (newValue) => _updateValue(property.key, newValue),
        labels: labels,
      ),
    );
  }

  Widget _buildIconField(IconProperty property) {
    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) => _updateEnable(property.key, enabled),
      child: PropertyIconField(
        label: property.displayName,
        value: property.value,
        onChanged: (newValue) => _updateValue(property.key, newValue),
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
