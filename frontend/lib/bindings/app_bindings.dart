import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/property_editor_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize CanvasController first as PropertyEditorController depends on it
    Get.put<CanvasController>(CanvasController(), permanent: true);
    
    // Initialize PropertyEditorController
    Get.put<PropertyEditorController>(PropertyEditorController(), permanent: true);
  }
}