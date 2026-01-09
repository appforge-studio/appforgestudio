import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';

import '../../globals.dart';
import '../../providers/providers.dart';

class Tab {
  String key;
  String name;
  String icon;
  double iconSize;
  Color color;
  Color bg;
  Tab({
    required this.key,
    required this.name,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.bg,
  });
}

List<Tab> tabs = [
  Tab(
    key: "design",
    name: "Design",
    icon: "assets/icons/design-tab.svg",
    iconSize: 17,
    color: Color(0xFF86C6EA),
    bg: Color(0xFF1A212B),
  ),
  Tab(
    key: "database",
    name: "Database",
    icon: "assets/icons/server-tab.svg",
    iconSize: 24,
    color: Color(0xFF7363E0),
    bg: Color(0xFF1F1A2B),
  ),
];

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  bool isHovered = false;
  final AppTabController appTabController = Get.find<AppTabController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppTabController>(
      builder: (controller) {
        final selectedTab = controller.selectedTab;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isHovered ? 60 : 10,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: isHovered ? 1.0 : 0.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Pallet.divider),
                  color: Color(0xFF16151A),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    for (var tab in tabs)
                      InkWell(
                        onTap: () {
                          appTabController.setTab(tab.key);
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: 18),
                          padding: padding(tab, selectedTab),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: selectedTab == tab.key
                                ? tab.bg.withOpacity(0.8)
                                : Colors.transparent,

                            boxShadow: [
                              if (selectedTab == tab.key)
                                BoxShadow(
                                  color: tab.bg.withOpacity(0.4),
                                  offset: const Offset(0, 2),
                                  blurRadius: 6,
                                  spreadRadius: 8,
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: tab.iconSize,
                                child: SvgPicture.asset(tab.icon),
                              ),
                              SizedBox(width: 8),
                              Text(tab.name, style: TextStyle(color: tab.color)),
                              // SizedBox(width: 2),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(width: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  padding(Tab tab, String selectedTab) {
    if (selectedTab == tab.key) {
      return EdgeInsets.symmetric(vertical: 5, horizontal: 12);
    } else if (selectedTab == tabs.first.key) {
      return EdgeInsets.only(right: 10);
    } else if (selectedTab == tabs.last.key) {
      return EdgeInsets.only(left: 10);
    }
    return EdgeInsets.zero;
  }
}

