import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/arri_service.dart';
import '../../../services/arri_client.rpc.dart';

class TypeController extends GetxController {
  final ArriService _arriService = Get.find<ArriService>();

  final RxList<Type> types = <Type>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<Type?> selectedType = Rx<Type?>(null);

  final codeController = TextEditingController();
  final enumValueController = TextEditingController();
  final RxList<String> currentEnumValues = <String>[].obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTypes();
  }

  Future<void> fetchTypes() async {
    isLoading.value = true;
    try {
      final response = await _arriService.client.admin.get_types(
        const GetTypesParams(),
      );
      types.assignAll(response.types);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch types: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectType(Type type) {
    selectedType.value = type;
    if (type.structure == 'enum') {
      try {
        currentEnumValues.assignAll(
          List<String>.from(jsonDecode(type.enumValues)),
        );
      } catch (_) {
        currentEnumValues.clear();
      }
    } else {
      codeController.text = type.code;
    }
  }

  Future<void> createType(
    String name,
    String className,
    String structure,
  ) async {
    Get.back(); // Close dialog
    try {
      final response = await _arriService.client.admin.create_type(
        CreateTypeParams(
          name: name,
          className: className,
          structure: structure,
        ),
      );

      if (response.success) {
        Get.snackbar('Success', response.message);
        fetchTypes();
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
        'Failed to create type: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    }
  }

  Future<void> saveTypeDefinition() async {
    if (selectedType.value == null) return;

    isSaving.value = true;
    try {
      final type = selectedType.value!;
      final response = await _arriService.client.admin.update_type_definition(
        UpdateTypeDefinitionParams(
          typeId: type.id,
          structure: type.structure,
          code: type.structure == 'enum' ? '' : codeController.text,
          enumValues: type.structure == 'enum'
              ? jsonEncode(currentEnumValues)
              : "[]",
        ),
      );

      if (response.success) {
        Get.snackbar('Success', 'Saved successfully');
        // Update local state to reflect changes if needed
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
        'Failed to save: $e',
        backgroundColor: Colors.red.withOpacity(0.2),
      );
    } finally {
      isSaving.value = false;
    }
  }

  void addEnumValue() {
    final val = enumValueController.text.trim();
    if (val.isNotEmpty && !currentEnumValues.contains(val)) {
      currentEnumValues.add(val);
      enumValueController.clear();
    }
  }

  void removeEnumValue(String val) {
    currentEnumValues.remove(val);
  }
}
