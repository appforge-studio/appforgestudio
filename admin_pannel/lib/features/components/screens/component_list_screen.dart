import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/component_controller.dart';

class ComponentListScreen extends StatelessWidget {
  const ComponentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ComponentController());

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
                    onPressed: () =>
                        _showAddComponentDialog(context, controller),
                    icon: const Icon(Icons.add),
                    label: const Text("Create Component"),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.components.isEmpty) {
                      return const Center(child: Text("No components found"));
                    }
                    return ListView.builder(
                      itemCount: controller.components.length,
                      itemBuilder: (context, index) {
                        final comp = controller.components[index];
                        return Obx(() {
                          final isSelected =
                              controller.selectedComponent.value?.name ==
                              comp.name;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            leading: const CircleAvatar(
                              child: Icon(Icons.widgets, size: 20),
                            ),
                            title: Text(
                              comp.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => controller.selectComponent(comp),
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
        // Editor Panel (Placeholder or actual editor)
        Expanded(
          flex: 2,
          child: Obx(() {
            final selected = controller.selectedComponent.value;
            if (selected == null) {
              return const Center(
                child: Text("Select a component to view details"),
              );
            }
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: "Code"),
                      Tab(text: "Properties"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Code Tab
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller:
                                      TextEditingController(
                                          text: controller
                                              .selectedComponentCode
                                              .value,
                                        )
                                        ..selection = TextSelection.collapsed(
                                          offset: controller
                                              .selectedComponentCode
                                              .value
                                              .length,
                                        ),
                                  onChanged: (val) =>
                                      controller.selectedComponentCode.value =
                                          val,
                                  maxLines: null,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "// Component code here...",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: controller.updateComponent,
                                icon: const Icon(Icons.save),
                                label: const Text("Save Code"),
                              ),
                            ],
                          ),
                        ),
                        // Properties Tab
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Properties",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddPropertyDialog(
                                      context,
                                      controller,
                                      forExisting: true,
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add Property"),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Expanded(
                                child: Obx(
                                  () => ListView.builder(
                                    itemCount: controller
                                        .selectedComponentProperties
                                        .length,
                                    itemBuilder: (ctx, i) {
                                      final p = controller
                                          .selectedComponentProperties[i];
                                      return ListTile(
                                        title: Text(p.name),
                                        subtitle: Text(
                                          "${p.type} = ${p.initialValue}",
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () =>
                                              controller.removeProperty(
                                                i,
                                                fromNew: false,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: controller.updateComponent,
                                  icon: const Icon(Icons.save),
                                  label: const Text("Save Properties"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showAddComponentDialog(
    BuildContext context,
    ComponentController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Component"),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller.nameController,
                  decoration: const InputDecoration(
                    labelText: "Component Name (enum value)",
                    hintText: "e.g., hero_header",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.classController,
                  decoration: const InputDecoration(
                    labelText: "Class Prefix (PascalCase)",
                    hintText: "e.g., HeroHeader",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Properties",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          _showAddPropertyDialog(context, controller),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Obx(
                    () => ListView.builder(
                      itemCount: controller.newProperties.length,
                      itemBuilder: (ctx, i) {
                        final p = controller.newProperties[i];
                        return ListTile(
                          dense: true,
                          title: Text(p.name),
                          subtitle: Text("${p.type} = ${p.initialValue}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => controller.removeProperty(i),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Custom Logic (component.dart body)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.codeController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText:
                        "// Add methods, overrides, or 'build' logic here...",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          FilledButton(
            onPressed: controller.createComponent,
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showAddPropertyDialog(
    BuildContext context,
    ComponentController controller, {
    bool forExisting = false,
  }) {
    String name = '';
    String type = controller.availableTypes.isNotEmpty
        ? controller.availableTypes.first.name
        : 'string';
    String initialValue = '';

    Get.dialog(
      AlertDialog(
        title: const Text("Add Property"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Name (camelCase)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: "Type",
                  border: OutlineInputBorder(),
                ),
                items: controller.availableTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.name,
                        child: Text(t.className),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => type = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Initial Value",
                  hintText: "e.g. 'Hello', 100, true, #FF0000",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => initialValue = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              controller.addProperty(
                name,
                type,
                initialValue,
                toNew: !forExisting,
              );
              Get.back();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
