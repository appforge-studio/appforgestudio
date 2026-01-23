import 'package:get/get.dart';

class SidebarController extends GetxController {
  // Selected page: 0 = Components, 1 = Layers, 2 = Data/Code
  final RxInt _selectedPage = 0.obs;
  int get selectedPage => _selectedPage.value;
  
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

