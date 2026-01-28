import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../controllers/canvas_controller.dart';
import '../../utilities/pallet.dart';

class VectorEditorPanel extends StatelessWidget {
  const VectorEditorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CanvasController>();

    return Container(
      width: double.infinity,
      color: Pallet.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const SizedBox(height: 20),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                    "Path Editor",
                    style: TextStyle(
                        color: Pallet.font1,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    )
                )
            ),
            const SizedBox(height: 20),
            _buildToolItem(
                icon: FontAwesomeIcons.pen,
                label: "Pen Tool",
                isActive: true, // For now assuming generic edit mode
                onTap: () {} 
            ),
             _buildToolItem(
                icon: FontAwesomeIcons.arrowPointer,
                label: "Selection",
                isActive: false,
                onTap: () {} 
            ),
            const Spacer(),
            Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Done"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12)
                        ),
                        onPressed: () {
                            controller.setEditingComponent(null);
                        },
                    )
                )
            )
        ],
      )
    );
  }

  Widget _buildToolItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
      return InkWell(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
              child: Row(
                  children: [
                      FaIcon(icon, size: 16, color: isActive ? Colors.blue : Pallet.font2),
                      const SizedBox(width: 12),
                      Text(label, style: TextStyle(color: isActive ? Colors.white : Pallet.font2))
                  ]
              )
          )
      );
  }
}
