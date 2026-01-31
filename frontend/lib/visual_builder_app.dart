import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bindings/app_bindings.dart';
import 'controllers/canvas_controller.dart';
import 'controllers/screens_controller.dart';
import 'utilities/pallet.dart';
import 'widgets/component_panel.dart';
import 'widgets/design_canvas.dart';
import 'widgets/property_editor.dart';

class VisualBuilderApp extends StatelessWidget {
  const VisualBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Visual Builder',
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansTextTheme(
          TextTheme(
            displayMedium: TextStyle(color: Pallet.font1),
            displayLarge: TextStyle(color: Pallet.font1),
            bodyMedium: TextStyle(color: Pallet.font1),
            bodyLarge: TextStyle(color: Pallet.font1),
            titleMedium: TextStyle(color: Pallet.font1),
          ),
        ),
        iconTheme: IconThemeData(color: Pallet.font2),
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
    final controller = Get.find<CanvasController>();
    final screensController = Get.find<ScreensController>();

    return Scaffold(
      backgroundColor: Pallet.background,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
              controller.undo(),
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: true,
            shift: true,
          ): () =>
              controller.redo(),
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
              controller.redo(),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // Global deselection - deselect when clicking anywhere except property editor
              // print('🎯 Global tap detected - deselecting component');
              Get.find<CanvasController>().onComponentDeselected();
            },
            child: Row(
              children: [
                // Component Panel (left side)
                const ComponentPanel(),

                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      // const UndoRedoToolbar(), // Removed per user request
                      // const SizedBox(height: 5),
                      // Design Canvas (center)
                      // Design Canvas (center)
                      Expanded(
                        child: Obx(() {
                          if (screensController.activeScreenId.value.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mobile_screen_share,
                                    size: 64,
                                    color: Pallet.font3.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Select or create a screen to start",
                                    style: TextStyle(
                                      color: Pallet.font3,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const DesignCanvas();
                        }),
                      ),
                    ],
                  ),
                ),

                // Property Editor (right side) - prevent deselection when clicking here
                GestureDetector(
                  behavior:
                      HitTestBehavior.opaque, // Block taps from reaching parent
                  onTap: () {
                    // Absorb taps to prevent deselection when clicking on property editor
                    // print('🎯 Property editor tap - not deselecting');
                  },
                  child: const PropertyEditor(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
