import 'package:get/get.dart';

class DashboardController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }
}
