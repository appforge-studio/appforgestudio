import 'dart:convert';

import 'package:frontend/providers/xd_tree.dart';

import '../globals.dart';
import '../providers/tree.dart';
import '../providers/providers.dart';
import '../widgets/container.dart';
import '../widgets/layout.dart';
import '../widgets/smart_guides.dart';
import '../providers/smart_guides.dart';
import '../utils/smart_guides_service.dart';
// import '../xd/main.dart';
import 'package:xd/xd.dart';

import 'package:dynamic_widget/dynamic_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class Simulator extends StatefulWidget {
  const Simulator({super.key});

  @override
  State<Simulator> createState() => _SimulatorState();
}

class _SimulatorState extends State<Simulator> {
  final size = Size(375, 667);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: size.width < 600 ? 2.0 : 1.0,
          ),
          child: Material(color: Colors.white, child: Screen()),
        ),
      ),
    );
  }
}

class DefaultClickListener implements ClickListener {
  DefaultClickListener();

  @override
  void onClicked(String? event) {
    if (event == null) return;
    final Map<String, dynamic> eventData = jsonDecode(event);

    switch (eventData['event']) {
      case 'onResize':
        _handleResize(eventData);
        break;
      case 'onDrop':
        _handleDrop(eventData);
        break;
      case 'onMarginChange':
        _handleMarginChange(eventData);
        break;
      default:
        print("Unknown event received: ${eventData['event']}");
    }
  }

  void _handleResize(Map<String, dynamic> eventData) {
    final treeController = Get.find<TreeController>();
    final tree = treeController.tree;
    if (tree == null) return;

    final String widgetId = eventData['id'];
    final double width = eventData['data']['width'];
    final double height = eventData['data']['height'];

    Component? component = treeController.getComponentById(widgetId);
    if (component == null) return;
    updateProperty(component, 'width', width);
    updateProperty(component, 'height', height);

    treeController.updateTree(tree);
    final xdTreeController = Get.find<XdTreeController>();
    xdTreeController.buildXDTree();
  }

  void _handleDrop(Map<String, dynamic> eventData) {
    print("kiarr");
    Component child = Component.fromJson(eventData["data"]);
    child.id = const Uuid().v4();

    // add default properties
    List<Property> childProperties = getComponentProperties(child.type);
    for (var property in childProperties) {
      if (property.value != null) {
        child.properties.add(property);
      }
    }

    final treeController = Get.find<TreeController>();
    Component? parent = treeController.getComponentById(eventData["id"]);
    if (parent == null) return;

    bool exists = false;
    Property? updatedProperty;
    for (var property in parent.properties) {
      if (property.xd_type == XDType.components) {
        // Create a new list to avoid mutating the original property.value
        List<Component> newChildren = List<Component>.from(property.value);
        newChildren.add(child);
        updatedProperty = property.copyWith(value: newChildren);
        exists = true;
        break;
      }
    }
    if (!exists) {
      Property property = getDroppableProperty(parent.type);
      if (property.xd_type == XDType.component) {
        property = property.copyWith(value: child);
      } else {
        property = property.copyWith(value: [child]);
      }
      parent.properties.add(property);
      updatedProperty = property;
    }

    // Update the parent in the tree using updateProperty
    if (updatedProperty != null) {
      treeController.updateProperty(parent.id!, updatedProperty);
    }

    final xdTreeController = Get.find<XdTreeController>();
    print(xdTreeController.xdTree);
    xdTreeController.buildXDTree();
    refreshSink.add("");
  }

  void _handleMarginChange(Map<String, dynamic> eventData) {
    final treeController = Get.find<TreeController>();
    final tree = treeController.tree;
    if (tree == null) return;

    final String widgetId = eventData['id'];
    final List<dynamic> marginList = eventData['data']['margin'];
    final List<double> margin = marginList
        .map((e) => (e as num).toDouble())
        .toList();

    Component? component = treeController.getComponentById(widgetId);
    if (component == null) return;
    updateProperty(component, 'margin', margin);

    // Update widget position for smart guides
    try {
      final position = SmartGuidesService.marginToPosition(margin);
      final width = _getPropertyValue(component, 'width')?.toDouble() ?? 200.0;
      final height =
          _getPropertyValue(component, 'height')?.toDouble() ?? 100.0;
      final widgetRect = SmartGuidesService.getWidgetRect(
        position,
        Size(width, height),
      );
      final widgetPositionsController = Get.find<WidgetPositionsController>();
      widgetPositionsController.updatePosition(widgetId, widgetRect);
    } catch (e) {
      print('Error updating widget position in margin change: $e');
    }

    treeController.updateTree(tree);
    final xdTreeController = Get.find<XdTreeController>();
    xdTreeController.buildXDTree();
  }

  // Helper function to get property value from component
  dynamic _getPropertyValue(Component component, String propertyName) {
    try {
      final property = component.properties.firstWhere(
        (prop) => prop.xd_name == propertyName,
      );
      return property.value;
    } catch (e) {
      return null;
    }
  }
}

class Screen extends StatefulWidget {
  const Screen({super.key});

  @override
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  bool dropping = false;
  late DefaultClickListener listener;

  @override
  void initState() {
    listener = DefaultClickListener();
    DynamicWidgetBuilder.addParser(XDContainer());
    DynamicWidgetBuilder.addParser(XDLayout());

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
      stream: refreshStream,
      builder: (context, snapshot) {
        return Scaffold(body: buildScreen());
      },
    );
  }

  buildScreen() {
    return GetBuilder<XdTreeController>(
      builder: (controller) {
        final jsonString = controller.xdTree;
        if (jsonString.isEmpty) {
          return DragTarget<Component>(
            onAcceptWithDetails: (DragTargetDetails<Component> details) {
              dropping = false;
              // if tree;
              final newTree = Component(
                id: Uuid().v4(),
                type: details.data.type,
                fl_name: details.data.fl_name,
                display_name: details.data.display_name,
                display_icon: details.data.display_icon,
                properties: [],
              );
              final treeController = Get.find<TreeController>();
              treeController.setTree(newTree);
              final componentController = Get.find<ComponentController>();
              componentController.setComponent(details.data);
              final xdTreeController = Get.find<XdTreeController>();
              xdTreeController.buildXDTree();

              print(xdTreeController.xdTree); // jsonString = '{"type":"XDContainer"}';
              setState(() {});
            },
            onWillAcceptWithDetails: (details) {
              print("kiar");
              dropping = true;
              setState(() {});
              return true;
            },
            onLeave: (data) {
              dropping = false;
              setState(() {});
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: dropping ? Colors.blue.withOpacity(0.1) : Colors.white,
                  border: dropping
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: const Center(
                  child: Text(
                    "Drop a widget here",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
          );
        }

        return Stack(
          children: [
            DynamicWidgetBuilder.build(jsonString, context, listener) ?? 
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                child: const Center(
                  child: Text(
                    "No widget to display",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            SmartGuidesOverlay(
              canvasSize: const Size(375, 667),
            ),
          ],
        );
      },
    );
  }
}