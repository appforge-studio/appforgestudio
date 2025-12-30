import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/app_bindings.dart';
import 'controllers/canvas_controller.dart';
import 'widgets/component_panel.dart';
import 'widgets/design_canvas.dart';
import 'widgets/property_editor.dart';
import 'widgets/overlay_demo.dart';

class VisualBuilderApp extends StatelessWidget {
  const VisualBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Visual Builder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialBinding: AppBindings(),
      home: const VisualBuilderHome(),
    );
  }
}

class VisualBuilderHome extends StatelessWidget {
  const VisualBuilderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Builder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OverlayDemo(),
                ),
              );
            },
            child: const Text(
              'Overlay Demo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Global deselection - deselect when clicking anywhere except property editor
          print('🎯 Global tap detected - deselecting component');
          Get.find<CanvasController>().onComponentDeselected();
        },
        child: Row(
          children: [
            // Component Panel (left side)
            const ComponentPanel(),
            // Design Canvas (center)
            const Expanded(
              flex: 2,
              child: DesignCanvas(),
            ),
            // Property Editor (right side) - prevent deselection when clicking here
            GestureDetector(
              behavior: HitTestBehavior.opaque, // Block taps from reaching parent
              onTap: () {
                // Absorb taps to prevent deselection when clicking on property editor
                print('🎯 Property editor tap - not deselecting');
              },
              child: const PropertyEditor(),
            ),
          ],
        ),
      ),
    );
  }
}