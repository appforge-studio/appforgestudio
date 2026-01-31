import '../providers/parent.dart';
import '../providers/tree.dart';
import 'package:xd/xd.dart';
import 'package:get/get.dart';

List order = ['Data', 'Components', 'Layout', 'Appearance', 'Animation'];

class PropertyGroup {
  String name;
  List<Property> properties;
  PropertyGroup({required this.name, required this.properties});
}

class PropertyController extends GetxController {
  List<PropertyGroup> _propertyGroups = [];
  List<PropertyGroup> get propertyGroups => _propertyGroups;

  setProperties(Component component) async {
    final treeController = Get.find<TreeController>();
    final tree = treeController.tree;

    List<PropertyGroup> propertyGroups = [];
    setParentStack(tree!);
    List parents = getParentLine(component.id!);

    Component? parent;
    if (parents.isNotEmpty) {
      parent = treeController.getComponentById(parents[0]);
    }

    // bool showLoop = false;

    // ref.read(selectedWidgetProvider.notifier).state = component.id!;

    // selectedWidget = component.id!;
    // controls = [];

    // widgethSink.add(selectedWidget);

    // for (var property in parent?.properties ?? []) {
    //   if (property.xd_type == "components") {
    //     for (var val in property.value) {
    //       print(val);
    //       if (property.id == val.id) {
    //         showLoop = true;
    //       }
    //     }
    //   }
    // }

    // print(widget["name"]);
    List properties = getComponentProperties(component.type);
    for (var property in properties) {

      // set params
      for (var param in component.properties) {
        if (property.xd_name == param.xd_name) {
          property.value = param.value;
          property.is_code = param.is_code;
        }
      }

      // if (property["type"] == "side" || property["type"] == "corner") {
      //   if (property["value"] == null) {
      //     property["value"] = [0, 0, 0, 0];
      //   }
      //   bool same = true;
      //   var first = property["value"][0];

      //   for (var val in property["value"]) {
      //     if (first != val) {
      //       same = false;
      //     }
      //   }

      //   if (!same) {
      //     property["control_type"] = "side";
      //   } else {
      //     property["control_type"] = "all";
      //   }
      // }
      // if (property["data_type"].toString().toLowerCase() == "color") {
      //   if (property["value"].toString().split(".").length > 1) {
      //     String color = await getColor(property["value"]);
      //     property["value"] = "Color($color)";
      //   } else {
      //     String color = await getColor("Colors.white");
      //     property["value"] = "Color($color)";
      //   }
      // }
      // if (property["data_type"].toString().toLowerCase() == "icondata") {
      //   if (property["value"].toString().split(".").length > 1) {
      //     property["value"] = await getIcon(property["value"]);
      //   }
      // }
      // if (property["type"].toString().toLowerCase() == "shadow") {
      //   if (property["value"] != null &&
      //       property["value"]["color"].toString().split(".").length > 1) {
      //     String color = await getColor(property["value"]["color"]);
      //     property["value"] = {"color": "Color($color)"};
      //   } else {
      //     String color = await getColor("Colors.transparent");
      //     property["value"] = {"color": "Color($color)"};
      //   }
      // }

      bool exists = false;
      for (var group in propertyGroups) {
        if (property.xd_group == group.name) {
          exists = true;
          group.properties.add(property);
        }
      }
      if (!exists) {
        propertyGroups.add(
          PropertyGroup(name: property.xd_group, properties: [property]),
        );
      }
    }

    // Sort the property groups based on the 'order' list
    propertyGroups.sort((a, b) {
      final aIndex = order.indexOf(a.name);
      final bIndex = order.indexOf(b.name);
      final effectiveAIndex = aIndex == -1 ? order.length : aIndex;
      final effectiveBIndex = bIndex == -1 ? order.length : bIndex;
      return effectiveAIndex.compareTo(effectiveBIndex);
    });

    _propertyGroups = propertyGroups;
    update();
  }
}

// Controller is initialized in providers.dart