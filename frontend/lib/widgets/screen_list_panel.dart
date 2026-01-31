import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/screens_controller.dart';
import '../utilities/pallet.dart';
import '../utilities/api_key_helper.dart';
import 'create_item_overlay_button.dart';

class ScreenListPanel extends StatelessWidget {
  const ScreenListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScreensController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Screens',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              CreateItemOverlayButton(
                onSave: (name, colorId) async {
                  // Check API Key before creating screen
                  // Technically we might want to check this *before* opening the overlay,
                  // but the overlay is a widget that manages its own state.
                  // Simpler: Check API key when they try to save, or wrap the button.
                  final apiKey = await ApiKeyHelper.checkApiKey(context);
                  if (apiKey != null) {
                    controller.addScreen(name);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Obx(
            () => controller.screens.isEmpty
                ? const Center(
                    child: Text(
                      'No screens yet',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: controller.screens.length,
                    itemBuilder: (context, index) {
                      final screen = controller.screens[index];
                      return InkWell(
                        onTap: () => controller.loadScreen(screen.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: controller.activeScreenId.value == screen.id
                                ? Pallet.inside3
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(color: Pallet.divider),
                            ),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.mobile,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  screen.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              // Delete option (could be hidden behind hover/menu)
                              InkWell(
                                onTap: () => controller.deleteScreen(screen.id),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // Dialog methods removed as they are replaced by CreateItemOverlayButton
}
