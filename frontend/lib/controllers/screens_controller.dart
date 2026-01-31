import 'package:get/get.dart';

import '../models/screen_model.dart';
import '../services/arri_client.rpc.dart';
import 'sidebar_controller.dart';
import 'canvas_controller.dart';

class ScreensController extends GetxController {
  final RxList<ScreenModel> screens = <ScreenModel>[].obs;
  final RxString activeScreenId = ''.obs;

  ScreenModel? get activeScreen =>
      screens.firstWhereOrNull((s) => s.id == activeScreenId.value);

  @override
  void onInit() {
    super.onInit();
    _loadScreens();
  }

  Future<void> _loadScreens() async {
    try {
      final client = Get.find<ArriClient>();
      final result = await client.screens.get_screens(GetScreensParams());
      if (isClosed) return;

      screens.value = result.screens
          .map(
            (s) => ScreenModel(
              id: s.id,
              name: s.name,
              content: s.content,
              createdAt: s.createdAt,
              lastModified: s.updatedAt,
            ),
          )
          .toList();
    } catch (e) {}
  }

  Future<void> addScreen(String name) async {
    try {
      final client = Get.find<ArriClient>();
      final result = await client.screens.create_screen(
        CreateScreenParams(name: name),
      );

      if (isClosed) return;

      final newScreen = ScreenModel(
        id: result.id,
        name: result.name,
        // The RPC returns content, but we should probably trust it's empty "[]" or similar
        content: result.content,
        createdAt: result.createdAt,
        lastModified: result.updatedAt,
      );

      screens.add(newScreen);

      // Load the new screen (clears canvas and navigates)
      loadScreen(newScreen.id);
    } catch (e) {}
  }

  Future<void> deleteScreen(String id) async {
    try {
      final client = Get.find<ArriClient>();
      await client.screens.delete_screen(DeleteScreenParams(id: id));
      if (isClosed) return;
      screens.removeWhere((s) => s.id == id);
    } catch (e) {}
  }

  // Future expansion: Load screen content into CanvasController
  void loadScreen(String id) {
    var screen = screens.firstWhereOrNull((s) => s.id == id);
    if (screen != null) {
      activeScreenId.value = id;

      // Load screen content into CanvasController
      if (Get.isRegistered<CanvasController>()) {
        Get.find<CanvasController>().loadFromJson(screen.content);
      }

      // Navigate to components view
      if (Get.isRegistered<SidebarController>()) {
        Get.find<SidebarController>().setSelectedPage(
          SidebarController.PAGE_COMPONENTS,
        );
      }
    }
  }

  Future<void> updateActiveScreenContent(String jsonContent) async {
    final index = screens.indexWhere((s) => s.id == activeScreenId.value);
    if (index != -1) {
      final screen = screens[index];

      try {
        final client = Get.find<ArriClient>();
        final response = await client.screens.update_screen(
          UpdateScreenParams(id: screen.id, content: jsonContent),
        );

        if (response.success) {
          if (isClosed) return;
          screens[index] = screen.copyWith(
            content: jsonContent,
            lastModified: response.updatedAt,
          );
        } else {}
      } catch (e) {}
    } else {}
  }
}
