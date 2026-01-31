import 'package:get/get.dart';

class SidebarController extends GetxController {
  // Selected page: 0 = Screens, 1 = Components, 2 = Layers, 3 = Data/Code
  final RxInt _selectedPage = 0.obs;
  int get selectedPage => _selectedPage.value;

  static const int PAGE_SCREENS = 0;
  static const int PAGE_COMPONENTS = 1;
  static const int PAGE_LAYERS = 2;
  static const int PAGE_DATA = 3;

  void setSelectedPage(int page) {
    _selectedPage.value = page;
  }

  // Divider position for resizable panels (0.0 to 1.0)
  final RxDouble _dividerPosition = 0.7.obs;
  double get dividerPosition => _dividerPosition.value;

  void setDividerPosition(double position) {
    _dividerPosition.value = position.clamp(0.2, 0.8);
  }
}
