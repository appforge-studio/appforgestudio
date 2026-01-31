import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:xd/xd.dart';

import '../globals.dart';
import 'tree.dart';
import 'properties.dart';
import 'smart_guides.dart';
import 'xd_tree.dart';

class ComponentController extends GetxController {
  Component? _component;
  Component? get component => _component;
  
  void setComponent(Component? component) {
    _component = component;
    update();
  }
}

class AppTabController extends GetxController {
  String _selectedTab = "design";
  String get selectedTab => _selectedTab;
  
  void setTab(String tab) {
    _selectedTab = tab;
    update();
  }
}

class DividerPositionController extends GetxController {
  double _dividerPosition = 0.7;
  double get dividerPosition => _dividerPosition;
  
  void setDividerPosition(double position) {
    _dividerPosition = position;
    update();
  }
}

class SelectedControlPageController extends GetxController {
  int _selectedPage = 0;
  int get selectedPage => _selectedPage;
  
  void setSelectedPage(int page) {
    _selectedPage = page;
    update();
  }
}

String selectedWidget = "";
selectWidget(String id) async {
  selectedWidget = id;
  
  // Get the component and populate properties panel
  final treeController = Get.find<TreeController>();
  final component = treeController.getComponentById(id);
  if (component != null) {
    final propertyController = Get.find<PropertyController>();
    await propertyController.setProperties(component);
  }
  
  refreshSink.add("");
}

String droppingWidget = "";

// Initialize all controllers
void initializeControllers() {
  Get.put(ComponentController());
  Get.put(AppTabController());
  Get.put(DividerPositionController());
  Get.put(SelectedControlPageController());
  Get.put(TreeController());
  Get.put(PropertyController());
  Get.put(SmartGuidesController());
  Get.put(WidgetPositionsController());
  Get.put(XdTreeController());
}

// Controller instances
final componentController = Get.put(ComponentController());
final appTabController = Get.put(AppTabController());
final dividerPositionController = Get.put(DividerPositionController());
final selectedControlPageController = Get.put(SelectedControlPageController());
final treeController = Get.put(TreeController());
final propertyController = Get.put(PropertyController());
final smartGuidesController = Get.put(SmartGuidesController());
final widgetPositionsController = Get.put(WidgetPositionsController());
final xdTreeController = Get.put(XdTreeController());

class ResizeState {
  final double startWidth;
  final double startHeight;
  final Offset startPosition;

  ResizeState({
    required this.startWidth,
    required this.startHeight,
    required this.startPosition,
  });
}
