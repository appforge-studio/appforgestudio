import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../globals.dart';
import '../providers/properties.dart';
import '../providers/tree.dart';
import '../providers/providers.dart';
// import '../xd/components.dart';
import 'package:xd/xd.dart';
import 'widgets/code_editor/code_editor.dart';
import 'widgets/texbox.dart';
import 'widgets/tree.dart';

double controlWidth = 280;

class Controls extends StatelessWidget {
  const Controls({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TreeController>(
      builder: (treeController) {
        final tree = treeController.tree;
        return GetBuilder<DividerPositionController>(
          builder: (dividerController) {
            final dividerPosition = dividerController.dividerPosition;
            return GetBuilder<SelectedControlPageController>(
              builder: (pageController) {
                final selectedPage = pageController.selectedPage;
                final propertyController = Get.find<PropertyController>();

    return SizedBox(
      width: controlWidth,
      child: Column(
        children: [
          // your logo row stays outside the split region
          SizedBox(height: 10),
          Row(
            children: [
              SizedBox(width: 10),
              Image.asset("assets/logo_square.png", height: 30),
              SizedBox(width: 5),
              Image.asset("assets/logo.png", height: 40),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 10),
                Column(
                  children: [
                    SizedBox(height: 30),
                    _iconButton(
                      icon: FontAwesomeIcons.mobile,
                      selected: selectedPage == 0,
                      onTap: () => pageController.setSelectedPage(0),
                    ),
                    SizedBox(height: 10),
                    _iconButton(
                      icon: FontAwesomeIcons.layerGroup,
                      selected: selectedPage == 1,
                      onTap: () => pageController.setSelectedPage(1),
                    ),
                    SizedBox(height: 10),
                    _iconButton(
                      icon: FontAwesomeIcons.server,
                      selected: selectedPage == 2,
                      onTap: () => pageController.setSelectedPage(2),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16151a),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _dataPage(
                      isDataPage: selectedPage == 2,
                      tree: tree,
                      treeController: treeController,
                      dividerPosition: dividerPosition,
                      dividerController: dividerController,
                      propertyController: propertyController,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
              },
            );
          },
        );
      },
    );
  }

  Widget _iconButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FaIcon(icon, color: Pallet.inside3, size: 22),
      ),
    );
  }

  Widget   _dataPage({
    required bool isDataPage,
    required dynamic tree,
    required TreeController treeController,
    required double dividerPosition,
    required DividerPositionController dividerController,
    required PropertyController propertyController,
  }) {
    if (isDataPage) {
      return Column(
        children: [
          CodeEditor(
            padding: EdgeInsets.zero,
            backgroundColor: Pallet.inside2,
            borderRadius: 10,
            model: EditorModel(
              files: [
                FileEditor(
                  name: "test.dart",
                  language: "dart",
                  code: "", // [code] needs a string
                ),
              ], // the files created above
              styleOptions: EditorModelStyleOptions(
                fontSize: 13,
                theme: myTheme, // Use the custom theme from Theme.dart
                textStyleOfTextField: TextStyle(
                  color: Colors.white, // Set font color to white
                  fontSize: 13,
                  fontFamily: "monospace",
                ),
              ),
            ),
            disableNavigationbar: false, // hide the navigation bar ? default is `false`
            // when the user confirms changes in one of the files:
            onSubmit: (String language, String value) {
              print("A file was changed.");
            },
            // the html code will be auto-formatted
            // after any modification to an HTML file
            formatters: const ["html"],
            textModifier: (String language, String content) {
              print("A file is about to change");

              // transform the code before it is saved
              // if you need to perform some operations on it
              // like your own auto-formatting for example
              return content;
            },
          ),
          Expanded(child: SizedBox()),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final paneHeight = constraints.maxHeight;
        final topFlex = (dividerPosition * 100).clamp(20, 80).toInt();
        final bottomFlex = 100 - topFlex;
        return Container(
          child: Column(
            children: [
              Flexible(
                flex: topFlex,
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Layers",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          children: [
                            if (tree != null)
                              Tree(
                                indent: 0,
                                data: tree,
                                isOpen: tree.is_open,
                                onTap: () async {
                                  await selectWidget(tree.id!);
                                  treeController.open(
                                    tree.id!,
                                    isOpen: !tree.is_open,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (DragUpdateDetails details) {
                    final dy = details.primaryDelta!;
                    final deltaRatio = dy / paneHeight;
                    final newPos = (dividerPosition + deltaRatio).clamp(
                      0.2,
                      0.8,
                    );
                    dividerController.setDividerPosition(newPos);
                  },
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Pallet.divider)),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: bottomFlex,
                child: ListView(
                  children: [
                    const SearchBox(),
                    const SizedBox(height: 10),
                    for (var component in components)
                      Draggable<Component>(
                        data: component,
                        feedback: componentTile(component, isDragging: true),
                        childWhenDragging: componentTile(
                          component,
                          isDragging: true,
                        ),
                        child: componentTile(component),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget componentTile(Component component, {bool isDragging = false}) {
    return Container(
      width: controlWidth,
      height: 40,
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey : null,
        border: Border(bottom: BorderSide(color: Pallet.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          SizedBox(height: 13, child: SvgPicture.asset(component.display_icon)),
          const SizedBox(width: 7),
          Text(component.display_name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
