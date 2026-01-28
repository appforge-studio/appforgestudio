import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/arri_client.rpc.dart';
import '../services/socket_service.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/property_editor_controller.dart';
import '../controllers/sidebar_controller.dart';

class AppBindings extends Bindings {
  static const String baseUrl = "http://127.0.0.1:5000";

  /// Helper to get full asset URL from relative path
  static String getAssetUrl(String path) {
    if (path.isEmpty) return "";
    if (path.startsWith('http') ||
        path.startsWith('assets/') ||
        path.startsWith('data:'))
      return path;

    // Clean path to ensure it starts with /
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return "$baseUrl$cleanPath";
  }

  @override
  void dependencies() {
    // Initialize ArriClient
    Get.put<ArriClient>(
      ArriClient(
        baseUrl: baseUrl,
        httpClient: http.Client(),
        timeout: const Duration(minutes: 2),
      ),
      permanent: true,
    );

    // Initialize SocketService
    Get.put<SocketService>(SocketService(), permanent: true);

    // Initialize CanvasController first as PropertyEditorController depends on it
    Get.put<CanvasController>(CanvasController(), permanent: true);

    // Initialize PropertyEditorController
    Get.put<PropertyEditorController>(
      PropertyEditorController(),
      permanent: true,
    );

    // Initialize SidebarController
    Get.put<SidebarController>(SidebarController(), permanent: true);
  }
}
