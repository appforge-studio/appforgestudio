import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/property_editor_controller.dart';
import '../models/component_model.dart';
import '../models/enums.dart';
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
                  Icon(
                    _getIconForComponentType(component.type),
                    size: 20,
                    color: Colors.blue,
                  ),
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
                child: _buildPropertyFields(component, controller),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPropertyFields(
    ComponentModel component,
    PropertyEditorController controller,
  ) {
    switch (component.type) {
      case ComponentType.container:
        return ContainerPropertyEditor(
          properties: component.properties,
          onChanged: (newProperties) {
            controller.updateComponentProperties(component, newProperties);
          },
        );
      case ComponentType.text:
        return TextPropertyEditor(
          properties: component.properties,
          onChanged: (newProperties) {
            controller.updateComponentProperties(component, newProperties);
          },
        );
      case ComponentType.image:
        return ImagePropertyEditor(
          properties: component.properties,
          onChanged: (newProperties) {
            controller.updateComponentProperties(component, newProperties);
          },
        );
    }
  }

  IconData _getIconForComponentType(ComponentType type) {
    switch (type) {
      case ComponentType.container:
        return Icons.crop_square;
      case ComponentType.text:
        return Icons.text_fields;
      case ComponentType.image:
        return Icons.image;
    }
  }
}

// Container Property Editor
class ContainerPropertyEditor extends StatelessWidget {
  final ComponentProperties properties;
  final Function(ComponentProperties) onChanged;

  const ContainerPropertyEditor({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumberField('width', 'Width'),
        const SizedBox(height: 16),
        _buildNumberField('height', 'Height'),
        const SizedBox(height: 16),
        _buildColorField('backgroundColor', 'Background Color'),
        const SizedBox(height: 16),
        _buildNumberField('borderRadius', 'Border Radius'),
        const SizedBox(height: 16),
        _buildSideField('padding', 'Padding'),
      ],
    );
  }

  Widget _buildNumberField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key) as NumberProperty;

    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) {
        final updatedProperties = properties.updatePropertyEnabled(
          key,
          enabled,
        );
        onChanged(updatedProperties);
      },
      child: PropertyTextField(
        label: label,
        value: property.value.toString(),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final numValue = double.tryParse(value);
          if (numValue != null) {
            final updatedProperties = properties.updateProperty(key, numValue);
            onChanged(updatedProperties);
          }
        },
      ),
    );
  }

  Widget _buildColorField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key)
            as ComponentColorProperty;

    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) {
        final updatedProperties = properties.updatePropertyEnabled(
          key,
          enabled,
        );
        onChanged(updatedProperties);
      },
      child: PropertyColorField(
        label: label,
        value: property.value,
        onChanged: (newValue) {
          final updatedProperties = properties.updateProperty(key, newValue);
          onChanged(updatedProperties);
        },
      ),
    );
  }

  Widget _buildSideField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key) as SideProperty;

    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) {
        final updatedProperties = properties.updatePropertyEnabled(
          key,
          enabled,
        );
        onChanged(updatedProperties);
      },
      child: PropertyTextField(
        label: label,
        value: property.value.values.first.toString(),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final numValue = double.tryParse(value);
          if (numValue != null) {
            // For simplicity, we'll update all sides with the same value
            final newSide = XDSide.all(numValue);
            final updatedProperties = properties.updateProperty(key, newSide);
            onChanged(updatedProperties);
          }
        },
      ),
    );
  }
}

// Text Property Editor
class TextPropertyEditor extends StatelessWidget {
  final ComponentProperties properties;
  final Function(ComponentProperties) onChanged;

  const TextPropertyEditor({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStringField('content', 'Text Content'),
        const SizedBox(height: 16),
        _buildNumberField('fontSize', 'Font Size'),
        const SizedBox(height: 16),
        _buildColorField('color', 'Text Color'),
        const SizedBox(height: 16),
        _buildDropdownField<TextAlign>('alignment', 'Text Alignment'),
        const SizedBox(height: 16),
        _buildDropdownField<FontWeight>('fontWeight', 'Font Weight'),
        const SizedBox(height: 16),
        _buildStringField('fontFamily', 'Font Family'),
      ],
    );
  }

  Widget _buildStringField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key) as StringProperty;

    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) {
        final updatedProperties = properties.updatePropertyEnabled(
          key,
          enabled,
        );
        onChanged(updatedProperties);
      },
      child: PropertyTextField(
        label: label,
        value: property.value,
        onChanged: (value) {
          final updatedProperties = properties.updateProperty(key, value);
          onChanged(updatedProperties);
        },
      ),
    );
  }

  Widget _buildNumberField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key) as NumberProperty;

    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) {
        final updatedProperties = properties.updatePropertyEnabled(
          key,
          enabled,
        );
        onChanged(updatedProperties);
      },
      child: PropertyTextField(
        label: label,
        value: property.value.toString(),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final numValue = double.tryParse(value);
          if (numValue != null) {
            final updatedProperties = properties.updateProperty(key, numValue);
            onChanged(updatedProperties);
          }
        },
      ),
    );
  }

  Widget _buildColorField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key)
            as ComponentColorProperty;

    return EnablePropertyWrapper(
      property: property,
      onEnableChanged: (enabled) {
        final updatedProperties = properties.updatePropertyEnabled(
          key,
          enabled,
        );
        onChanged(updatedProperties);
      },
      child: PropertyColorField(
        label: label,
        value: property.value,
        onChanged: (newValue) {
          final updatedProperties = properties.updateProperty(key, newValue);
          onChanged(updatedProperties);
        },
      ),
    );
  }

  Widget _buildDropdownField<T>(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key)
            as DropdownProperty<T>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: property.value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: property.options.map((T option) {
            return DropdownMenuItem<T>(
              value: option,
              child: Text(property.displayText(option)),
            );
          }).toList(),
          onChanged: (T? newValue) {
            if (newValue != null) {
              final updatedProperties = properties.updateProperty(
                key,
                newValue,
              );
              onChanged(updatedProperties);
            }
          },
        ),
      ],
    );
  }
}

// Image Property Editor
class ImagePropertyEditor extends StatelessWidget {
  final ComponentProperties properties;
  final Function(ComponentProperties) onChanged;

  const ImagePropertyEditor({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStringField('source', 'Image Source'),
        const SizedBox(height: 16),
        _buildNumberField('width', 'Width'),
        const SizedBox(height: 16),
        _buildNumberField('height', 'Height'),
        const SizedBox(height: 16),
        _buildDropdownField<BoxFit>('fit', 'Image Fit'),
        const SizedBox(height: 16),
        _buildNumberField('borderRadius', 'Border Radius'),
      ],
    );
  }

  Widget _buildStringField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key) as StringProperty;

    return PropertyTextField(
      label: label,
      value: property.value,
      onChanged: (value) {
        final updatedProperties = properties.updateProperty(key, value);
        onChanged(updatedProperties);
      },
    );
  }

  Widget _buildNumberField(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key) as NumberProperty;

    return PropertyTextField(
      label: label,
      value: property.value.toString(),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final numValue = double.tryParse(value);
        if (numValue != null) {
          final updatedProperties = properties.updateProperty(key, numValue);
          onChanged(updatedProperties);
        }
      },
    );
  }

  Widget _buildDropdownField<T>(String key, String label) {
    final property =
        properties.properties.firstWhere((p) => p.key == key)
            as DropdownProperty<T>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: property.value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: property.options.map((T option) {
            return DropdownMenuItem<T>(
              value: option,
              child: Text(property.displayText(option)),
            );
          }).toList(),
          onChanged: (T? newValue) {
            if (newValue != null) {
              final updatedProperties = properties.updateProperty(
                key,
                newValue,
              );
              onChanged(updatedProperties);
            }
          },
        ),
      ],
    );
  }
}
