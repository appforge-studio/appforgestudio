import 'package:get/get.dart';
import '../components/component_factory.dart';
import '../components/component_properties_factory.dart';
import '../models/component_model.dart';
import '../models/component_properties.dart';
import '../models/state_classes.dart';

import 'canvas_controller.dart';

class PropertyEditorController extends GetxController {
  final Rx<PropertyEditorState> _state = const PropertyEditorState().obs;

  // Getters for reactive state access
  PropertyEditorState get state => _state.value;
  ComponentModel? get selectedComponent => _state.value.selectedComponent;
  bool get isVisible => _state.value.isVisible;

  // Get canvas controller for component updates
  CanvasController get _canvasController => Get.find<CanvasController>();

  // Component selection management
  void selectComponent(ComponentModel? component) {
    _updateState(
      _state.value.copyWith(
        selectedComponent: component,
        isVisible: component != null,
      ),
    );
  }

  void clearSelection() {
    _updateState(
      _state.value.copyWith(selectedComponent: null, isVisible: false),
    );
  }

  // Property update methods using ComponentProperties
  void updateComponentProperties(
    ComponentModel component,
    ComponentProperties newProperties,
  ) {
    final updatedComponent = component.copyWith(properties: newProperties);
    _updateComponentAndNotifyCanvas(updatedComponent);
  }

  // Update specific property value
  void updatePropertyValue(String propertyKey, dynamic value) {
    final component = _state.value.selectedComponent;
    if (component == null) return;

    final updatedProperties = component.properties.updateProperty(
      propertyKey,
      value,
    );
    final updatedComponent = component.copyWith(properties: updatedProperties);
    _updateComponentAndNotifyCanvas(updatedComponent);
  }

  // Property validation methods
  bool validateComponentProperties(
    ComponentProperties properties,
    ComponentType type,
  ) {
    // Generic validation: ensure properties object exists and has properties
    return properties.properties.isNotEmpty;
  }

  // Get default properties for a component type
  ComponentProperties getDefaultPropertiesForType(ComponentType type) {
    return ComponentPropertiesFactory.getDefaultProperties(type);
  }

  // Get current properties
  ComponentProperties? getCurrentProperties() {
    return _state.value.selectedComponent?.properties;
  }

  // Get properties by component type
  ComponentProperties getPropertiesForComponent(ComponentModel component) {
    return component.properties;
  }

  // Check if current component is of specific type
  bool isCurrentComponentOfType(ComponentType type) {
    return _state.value.selectedComponent?.type == type;
  }

  // Get component type specific property fields count
  int getPropertyFieldsCount() {
    final component = _state.value.selectedComponent;
    if (component == null) return 0;

    return component.properties.properties.length;
  }

  // Get property value by key
  T? getPropertyValue<T>(String key) {
    final component = _state.value.selectedComponent;
    if (component == null) return null;

    return component.properties.getProperty<T>(key);
  }

  // Check if property exists
  bool hasProperty(String key) {
    final component = _state.value.selectedComponent;
    if (component == null) return false;

    return component.properties.properties.any((p) => p.key == key);
  }

  // Get all property keys for current component
  List<String> getPropertyKeys() {
    final component = _state.value.selectedComponent;
    if (component == null) return [];

    return component.properties.properties.map((p) => p.key).toList();
  }

  // Private methods
  void _updateComponentAndNotifyCanvas(ComponentModel updatedComponent) {
    // Update local state
    _updateState(_state.value.copyWith(selectedComponent: updatedComponent));

    // Notify canvas controller of the change
    _canvasController.onComponentPropertiesChanged(updatedComponent);
  }

  void _updateState(PropertyEditorState newState) {
    _state.value = newState;
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return _state.value.toJson();
  }

  void fromJson(Map<String, dynamic> json) {
    final selectedComponentJson =
        json['selectedComponent'] as Map<String, dynamic>?;
    ComponentModel? selectedComponent;

    if (selectedComponentJson != null) {
      // We need to get the component from canvas controller to maintain consistency
      final componentId = selectedComponentJson['id'] as String;
      selectedComponent = _canvasController.getComponentById(componentId);
    }

    _updateState(
      PropertyEditorState(
        selectedComponent: selectedComponent,
        isVisible: json['isVisible'] as bool? ?? false,
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();

    // Listen to canvas controller selection changes
    // We use debounce to delay the property editor update, making selection feel instant
    // as requested by the user ("it is okay if the property editor appears later").
    debounce(
      _canvasController.selectedComponentIds,
      (Set<String> selectedIds) {
        final primarySelection = _canvasController.selectedComponent;
        if (primarySelection != _state.value.selectedComponent) {
          selectComponent(primarySelection);
        }
      },
      time: const Duration(milliseconds: 150),
    );
  }
}
