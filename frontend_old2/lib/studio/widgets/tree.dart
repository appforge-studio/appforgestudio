import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';

import '../../globals.dart';
import '../../providers/tree.dart';
import 'package:xd/xd.dart';
import '../../providers/providers.dart';

Component? findComponentById(String id, Component tree) {
  if (tree.id == id) {
    return tree;
  }

  for (var property in tree.properties) {
    if (property.xd_type == XDType.components) {
      for (var child in property.value) {
        Component? found = findComponentById(id, child);
        if (found != null) return found;
      }
    } else if (property.xd_type == XDType.component) {
      Component? found = findComponentById(id, property.value);
      if (found != null) return found;
    }
  }

  return null;
}

bool hasChildren(List<Property> properties) {
  for (var property in properties) {
    if (property.xd_type == XDType.components) {
      return true;
    }
    if (property.xd_type == XDType.component) {
      return true;
    }
  }
  return false;
}

class Tree extends StatelessWidget {
  const Tree({
    super.key,
    required this.indent,
    required this.data,
    required this.isOpen,
    required this.onTap,
  });
  final int indent;
  final Component data;
  final bool isOpen;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TreeController>(
      builder: (treeController) {
        final currentTree = treeController.tree;

    // If this is the root tree, use the current tree from provider
    // Otherwise, find the current data in the updated tree
    Component currentData = data;
    if (currentTree != null && data.id == currentTree.id) {
      currentData = currentTree;
    } else if (currentTree != null) {
      // Find the current component in the updated tree
      Component? foundComponent = findComponentById(data.id!, currentTree);
      if (foundComponent != null) {
        currentData = foundComponent;
      }
    }

    return InkWell(
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: indent * 5),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: (selectedWidget == data.id) ? Color(0xFF221D43) : null,
                boxShadow: [
                  if (selectedWidget == data.id)
                    BoxShadow(
                      color: Color(0xFf221D43).withOpacity(0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                ],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 13,
                    child: SvgPicture.asset(currentData.display_icon),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    " ${currentData.display_name}",
                    style: TextStyle(color: Pallet.insideFont, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isOpen) ...[
              for (var property in currentData.properties) ...[
                if (property.xd_type == XDType.components) ...[
                  for (var child in property.value)
                    Tree(
                      indent: indent + 1,
                      data: child,
                      onTap: () async {
                        await selectWidget(child.id!);
                        treeController.open(child.id!, isOpen: !child.is_open);
                      },
                      isOpen: child.is_open ?? false,
                    ),
                ] else if (property.xd_type == XDType.component) ...[
                  Tree(
                    indent: indent + 1,
                    data: property.value,
                    isOpen: property.value.is_open ?? false,
                    onTap: () async {
                      await selectWidget(property.value.id!);
                      treeController.open(
                        property.value.id!,
                        isOpen: !property.value.is_open,
                      );
                    },
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
      },
    );
  }
}
