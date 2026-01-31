import 'package:xd/xd.dart';
import 'package:get/get.dart';

class TreeController extends GetxController {
  Component? _tree;
  Component? get tree => _tree;

  void setTree(Component tree) {
    _tree = tree;
    update();
  }

  void updateTree(Component tree) {
    _tree = tree;
    update();
  }

  void updateProperty(String componentId, Property newProperty) {
    if (_tree == null) return;

    Component? updateNode(Component node) {
      if (node.id == componentId) {
        final newProperties = node.properties.map((p) {
          if (p.xd_name == newProperty.xd_name) {
            return newProperty;
          }
          return p;
        }).toList();
        return node.copyWith(properties: newProperties);
      }

      final newProps = <Property>[];
      for (final p in node.properties) {
        if (p.xd_type == XDType.components) {
          final newChildren = p.value
              .map(updateNode)
              .whereType<Component>()
              .toList();
          newProps.add(p.copyWith(value: newChildren));
        } else if (p.xd_type == XDType.component && p.value != null) {
          final newChild = updateNode(p.value);
          if (newChild != null) {
            newProps.add(p.copyWith(value: newChild));
          } else {
            newProps.add(p);
          }
        } else {
          newProps.add(p);
        }
      }

      return node.copyWith(properties: newProps);
    }

    final newState = updateNode(_tree!);
    if (newState != null) {
      _tree = newState;
      update();
    }
  }

  void open(String componentId, {bool isOpen = true}) {
    if (_tree == null) return;

    Component? updateNode(Component node) {
      if (node.id == componentId) {
        return node.copyWith(is_open: isOpen);
      }

      final newProps = <Property>[];
      for (final p in node.properties) {
        if (p.xd_type == XDType.components) {
          final newChildren = p.value
              .map(updateNode)
              .whereType<Component>()
              .toList();
          newProps.add(p.copyWith(value: newChildren));
        } else if (p.xd_type == XDType.component && p.value != null) {
          final newChild = updateNode(p.value);
          if (newChild != null) {
            newProps.add(p.copyWith(value: newChild));
          } else {
            newProps.add(p);
          }
        } else {
          newProps.add(p);
        }
      }

      return node.copyWith(properties: newProps);
    }

    final newState = updateNode(_tree!);
    if (newState != null) {
      _tree = newState;
      update();
    }
  }

  /// Returns the component with the given [id] from the tree, or null if not found.
  Component? getComponentById(String id) {
    if (_tree == null) return null;
    return _getComponent(id, _tree!);
  }

  /// Internal recursive function to find a component by id.
  Component? _getComponent(String id, Component component) {
    if (component.id == id) {
      return component;
    }
    for (var parameter in component.properties) {
      if (parameter.xd_type == XDType.component) {
        Component? result = _getComponent(id, parameter.value);
        if (result?.id != null) {
          return result;
        }
      } else if (parameter.xd_type == XDType.components) {
        for (var i = 0; i < parameter.value.length; i++) {
          Component? result = _getComponent(id, parameter.value[i]);
          if (result?.id != null) {
            return result;
          }
        }
      }
    }
    return null;
  }
}

// Controller is initialized in providers.dart