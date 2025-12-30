import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/type_controller.dart';

class TypeEditorScreen extends GetView<TypeController> {
  const TypeEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final type = controller.selectedType.value;
      if (type == null) {
        return const Center(child: Text("Select a type to edit"));
      }

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Editing: ${type.className}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Structure: ${type.structure}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.saveTypeDefinition,
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text("Save"),
                ),
              ],
            ),
          ),
          Expanded(
            child: type.structure == 'enum'
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Enum Values",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Obx(
                            () => ListView(
                              children: controller.currentEnumValues
                                  .map(
                                    (val) => Card(
                                      child: ListTile(
                                        title: Text(val),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              controller.removeEnumValue(val),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.enumValueController,
                                decoration: const InputDecoration(
                                  labelText: "Add Value",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => controller.addEnumValue(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: controller.addEnumValue,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : TextField(
                    controller: controller.codeController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: "Enter custom code here...",
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      );
    });
  }
}
