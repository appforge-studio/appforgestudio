import 'package:get/get.dart';
import 'package:xd/xd.dart';
import 'dart:convert';
import 'tree.dart';

Map<String, dynamic> _buildXdTree(Component tree) {
  final Map<String, dynamic> data = {'id': tree.id, 'type': tree.type};
  for (final property in tree.properties) {
    if (property.value != null) {
      if (property.xd_type == XDType.component) {
        data[property.xd_name] = _buildXdTree(property.value);
      } else if (property.xd_type == XDType.components) {
        final list = <dynamic>[];
        for (final component in property.value) {
          list.add(_buildXdTree(component));
        }
        data[property.xd_name] = list;
      } else {
        data[property.xd_name] = property.value;
      }
    }
  }
  return data;
}

class XdTreeController extends GetxController {
  String _xdTree = "";
  String get xdTree => _xdTree;

  void buildXDTree() {
    final treeController = Get.find<TreeController>();
    final tree = treeController.tree;
    if (tree == null) {
      _xdTree = '';
      update();
      return;
    }
    _xdTree = jsonEncode(_buildXdTree(tree));
    update();
  }
}

// Controller is initialized in providers.dart