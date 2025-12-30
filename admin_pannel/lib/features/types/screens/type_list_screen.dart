import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/type_controller.dart';
import 'type_editor_screen.dart';

class TypeListScreen extends StatelessWidget {
  const TypeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final controller = Get.put(TypeController());

    return Row(
      children: [
        // List Panel
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTypeDialog(context, controller),
                    icon: const Icon(Icons.add),
                    label: const Text("Create Type"),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.types.isEmpty) {
                      return const Center(child: Text("No types found"));
                    }
                    return ListView.builder(
                      itemCount: controller.types.length,
                      itemBuilder: (context, index) {
                        final type = controller.types[index];
                        return Obx(() {
                          final isSelected =
                              controller.selectedType.value?.id == type.id;
                          final icon = type.structure == 'enum'
                              ? Icons.list
                              : Icons.code;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            leading: CircleAvatar(child: Icon(icon, size: 20)),
                            title: Text(
                              type.className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(type.name),
                            onTap: () => controller.selectType(type),
                          );
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        // Editor Panel
        const Expanded(flex: 2, child: TypeEditorScreen()),
      ],
    );
  }

  void _showAddTypeDialog(BuildContext context, TypeController controller) {
    final typeNameController = TextEditingController();
    final classNameController = TextEditingController();
    String structure = 'object';

    Get.dialog(
      AlertDialog(
        title: const Text("Create New Type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: structure,
              decoration: const InputDecoration(
                labelText: "Structure",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'object', child: Text("Object")),
                DropdownMenuItem(value: 'enum', child: Text("Enum")),
              ],
              onChanged: (val) => structure = val!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: typeNameController,
              decoration: const InputDecoration(
                labelText: "File Name (snake_case)",
                hintText: "e.g., texture_generator",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: classNameController,
              decoration: const InputDecoration(
                labelText: "Class Name (PascalCase)",
                hintText: "e.g., TextureGenerator",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          FilledButton(
            onPressed: () => controller.createType(
              typeNameController.text.trim(),
              classNameController.text.trim(),
              structure,
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
