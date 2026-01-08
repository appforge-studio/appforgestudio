import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/arri_client.rpc.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/property_editor_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize ArriClient
    Get.put<ArriClient>(
      ArriClient(baseUrl: "http://localhost:5000", httpClient: http.Client()),
      permanent: true,
    );

    // Initialize CanvasController first as PropertyEditorController depends on it
    Get.put<CanvasController>(CanvasController(), permanent: true);

    // Initialize PropertyEditorController
    Get.put<PropertyEditorController>(
      PropertyEditorController(),
      permanent: true,
    );
  }
}
