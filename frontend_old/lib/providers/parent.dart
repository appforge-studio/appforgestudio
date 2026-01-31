// parents stack
import 'package:xd/xd.dart';

Map parentStack = {};

getParentLine(String id) {
  List parents = [];
  String? parent = parentStack[id];
  while (parent != null) {
    parents.add(parent);
    id = parent;
    parent = parentStack[id];
  }
  return parents;
}

setParentStack(Component tree) {
  parentStack = {};
  _setParentStack(tree);
}

_setParentStack(Component component) {
  for (var parameter in component.properties) {
    if (parameter.xd_type == XDType.component) {
      parentStack[parameter.value.id] = component.id;
      _setParentStack(parameter.value);
    } else if (parameter.xd_type == XDType.components) {
      for (var i = 0; i < parameter.value.length; i++) {
        parentStack[parameter.value[i].id] = component.id;
        _setParentStack(parameter.value[i]);
      }
    }
  }
}
