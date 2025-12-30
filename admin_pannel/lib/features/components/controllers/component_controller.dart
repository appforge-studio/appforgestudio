import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/arri_service.dart';
import '../../../services/arri_client.rpc.dart';
// Note: We'll share the data classes from main.dart's old implementation
// but define them properly in a model file if needed.
// For now, mirroring simple structures.

class AdminComponentPropertyData {
  String name;
  String type;
  String initialValue;
  AdminComponentPropertyData({
    this.name = '',
    this.type = 'string',
    this.initialValue = '',
  });
}

class ComponentController extends GetxController {
  final ArriService _arriService = Get.find<ArriService>();

  final RxList<ComponentInfo> components = <ComponentInfo>[].obs;
  final RxList<Type> availableTypes = <Type>[].obs; // For property types
  final RxBool isLoading = false.obs;
  final Rx<ComponentInfo?> selectedComponent = Rx<ComponentInfo?>(null);
  final RxString selectedComponentCode = "".obs;
  final RxList<AdminComponentPropertyData> selectedComponentProperties =
      <AdminComponentPropertyData>[].obs;

  // Creation Form
  final nameController = TextEditingController();
  final classController = TextEditingController();
  final codeController = TextEditingController();
  final RxList<AdminComponentPropertyData> newProperties =
      <AdminComponentPropertyData>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchComponents();
    // We also need types to populate the property type dropdown
    fetchTypes();
  }

  Future<void> fetchComponents() async {
    isLoading.value = true;
    try {
      final response = await _arriService.client.admin.get_components(
        const GetComponentsParams(),
      );
      components.assignAll(response.components);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch components: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTypes() async {
    try {
      final response = await _arriService.client.admin.get_types(
        const GetTypesParams(),
      );
      availableTypes.assignAll(response.types);
    } catch (e) {
      // split silent
    }
  }

  void selectComponent(ComponentInfo comp) {
    selectedComponent.value = comp;
    selectedComponentCode.value = comp.code;

    // Parse properties string (assuming JSON array of {name, type, initialValue})
    try {
      final List<dynamic> propsJson = json.decode(comp.properties);
      selectedComponentProperties.assignAll(
        propsJson
            .map(
              (p) => AdminComponentPropertyData(
                name: p['name'] ?? '',
                type: p['type'] ?? 'string',
                initialValue: p['initialValue'] ?? '',
              ),
            )
            .toList(),
      );
    } catch (e) {
      selectedComponentProperties.clear();
      print("Error parsing component properties: $e");
    }
  }

  void addProperty(
    String name,
    String type,
    String initialValue, {
    bool toNew = true,
  }) {
    if (name.isNotEmpty) {
      final prop = AdminComponentPropertyData(
        name: name,
        type: type,
        initialValue: initialValue,
      );
      if (toNew) {
        newProperties.add(prop);
      } else {
        selectedComponentProperties.add(prop);
      }
    }
  }

  void removeProperty(int index, {bool fromNew = true}) {
    if (fromNew) {
      newProperties.removeAt(index);
    } else {
      selectedComponentProperties.removeAt(index);
    }
  }

  Future<void> updateComponent() async {
    final comp = selectedComponent.value;
    if (comp == null) return;

    Get.snackbar('Processing', 'Updating component...');

    try {
      final propertiesList = selectedComponentProperties
          .map(
            (p) => UpdateComponentParamsPropertiesElement(
              name: p.name,
              type: UpdateComponentParamsPropertiesElementType.fromString(
                p.type,
              ),
              initialValue: p.initialValue,
            ),
          )
          .toList();

      final response = await _arriService.client.admin.update_component(
        UpdateComponentParams(
          id: comp.id,
          properties: propertiesList,
          componentCode: selectedComponentCode.value,
        ),
      );

      if (response.success) {
        Get.snackbar('Success', response.message);
        fetchComponents();
      } else {
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red.withOpacity(0.2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update component: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    }
  }

  Future<void> createComponent() async {
    final name = nameController.text.trim();
    final className = classController.text.trim();
    final code = codeController.text;

    if (name.isEmpty || className.isEmpty) return;

    Get.back(); // Close dialog
    Get.snackbar('Processing', 'Creating component...');

    try {
      final propertiesList = newProperties
          .map(
            (p) => CreateComponentParamsPropertiesElement(
              name: p.name,
              type: p.type,
              initialValue: p.initialValue,
            ),
          )
          .toList();

      final response = await _arriService.client.admin.create_component(
        CreateComponentParams(
          name: name,
          className: className,
          properties: propertiesList,
          componentCode: code,
        ),
      );

      if (response.success) {
        Get.snackbar('Success', response.message);
        nameController.clear();
        classController.clear();
        codeController.clear();
        newProperties.clear();
        fetchComponents();
      } else {
        Get.snackbar(
          'Error',
          response.message,
          backgroundColor: Colors.red.withOpacity(0.2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create component: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    }
  }
}
