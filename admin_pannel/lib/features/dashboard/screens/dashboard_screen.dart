import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../types/screens/type_list_screen.dart';
import '../../components/screens/component_list_screen.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Refresh current tab content
              // Using a simple event bus or finding child controller could work
              // For now, let's just let the tabs handle their own refresh/init
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Obx(
            () => NavigationRail(
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: controller.changeTabIndex,
              labelType: NavigationRailLabelType.all,
              useIndicator: true,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.code_outlined),
                  selectedIcon: Icon(Icons.code),
                  label: Text('Types'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets),
                  label: Text('Components'),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Obx(
              () => IndexedStack(
                index: controller.selectedIndex.value,
                children: const [TypeListScreen(), ComponentListScreen()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
