import '../providers/properties.dart';
import '../providers/tree.dart';
import '../globals.dart';
import '../providers/providers.dart';
import 'package:xd/xd.dart';
// import '../xd/types.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'widgets/colorpicker/flutter_colorpicker.dart';
import 'widgets/enum.dart';
import 'widgets/texbox.dart';
import 'widgets/tree.dart';

class Properties extends StatelessWidget {
  const Properties({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PropertyController>(
      builder: (controller) {
        final groups = controller.propertyGroups;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: EdgeInsets.only(top: 10, bottom: 10, right: 10),
          decoration: BoxDecoration(
            color: Pallet.inside1,
            borderRadius: BorderRadius.circular(20),
          ),
          width: 300,
          child: ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  "Properties",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: 5),
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // if (showLoop)
                    //   InkWell(
                    //     onTap: () {
                    //       // addLoop(context);
                    //     },
                    //     child: Container(
                    //       margin: EdgeInsets.only(right: 5),
                    //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(15),
                    //         color: Pallet.inside1,
                    //       ),
                    //       child: Row(
                    //         children: [
                    //           Icon(Icons.loop, size: 18, color: Colors.green),
                    //           SizedBox(width: 5),
                    //           Text("Loop", style: TextStyle(fontSize: 12)),
                    //           SizedBox(width: 5),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    InkWell(
                      onTap: () {},
                      child: Container(
                        margin: EdgeInsets.only(right: 5),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Pallet.inside1,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.question_mark,
                              size: 18,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 2),
                            Text("Condition", style: TextStyle(fontSize: 12)),
                            SizedBox(width: 5),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        // screen["screen"][0] = deleteWidget(
                        //   selectedWidget,
                        //   screen["screen"][0],
                        // );
                        // await saveAndLoad();
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 5),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Pallet.inside1,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 2),
                            Text("Delete", style: TextStyle(fontSize: 12)),
                            SizedBox(width: 5),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              for (var group in groups) ...[
                SizedBox(height: 5),
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 10),

                  child: Text(
                    group.name.toUpperCase(),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                SizedBox(height: 5),
                for (var property in group.properties)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (property.xd_type == XDType.shadow)
                          shadow(property)
                        else if (property.xd_type == XDType.side ||
                            property.xd_type == XDType.corner)
                          side(property)
                        else
                          Expanded(
                            child: Text(
                              property.xd_name.toSentence(),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        if (property.xd_type == XDType.option)
                          SizedBox(
                            width: 90,
                            child: DropDown(
                              label:
                                  (property.value != null &&
                                      property.value.toString().contains('.'))
                                  ? property.value.split(".")[1]
                                  : "Select",
                              items: property.xd_data_type.values,
                              onPress: (value) {
                                final newEnumValue =
                                    "${property.xd_data_type}.${value}";
                                final newProperty = property.copyWith(
                                  value: newEnumValue,
                                  is_code: true,
                                );

                                final treeController =
                                    Get.find<TreeController>();
                                treeController.updateProperty(
                                  selectedWidget,
                                  newProperty,
                                );

                                final newTree = treeController.tree;
                                if (newTree != null) {
                                  final updatedComponent = findComponentById(
                                    selectedWidget,
                                    newTree,
                                  );
                                  if (updatedComponent != null) {
                                    final propertyController =
                                        Get.find<PropertyController>();
                                    propertyController.setProperties(
                                      updatedComponent,
                                    );
                                  }
                                }
                              },
                              menuDecoration: BoxDecoration(
                                color: Pallet.inside1,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        else if (property.xd_type == XDType.component)
                          SizedBox()
                        // AddButton(
                        //   type: "widgets",
                        //   onSelect: (name) async {
                        //     String id = Uuid().v4();
                        //     property["value"] = {
                        //       "type": "widget",
                        //       "id": id,
                        //       "name": name,
                        //       "properties": [],
                        //       "is_open": false,
                        //     };
                        //     screen["screen"][0] = setPropertyInTree(
                        //       property,
                        //       screen["screen"][0],
                        //     );
                        //     selectedWidget = id;
                        //     refreshSink.add("");
                        //   },
                        // )
                        else if (property.xd_type == "animations")
                          SizedBox()
                        // AddButton(
                        //   type: "animations",
                        //   onSelect: (value) {
                        //     print("add");
                        //   },
                        // )
                        else if (property.xd_type == XDType.value ||
                            property.xd_type == "text_controller")
                          if (property.xd_data_type == XDDataType.color)
                            Row(
                              children: [
                                Checkbox(
                                  value: property.value != null,
                                  onChanged: (bool? value) {
                                    //   print(value);
                                    //   if (value == false) {
                                    //     property["value"] = null;
                                    //   } else {
                                    //     property["value"] = "Color(4294967295)";
                                    //   }
                                    //   screen["screen"][0] = setPropertyInTree(
                                    //     property,
                                    //     screen["screen"][0],
                                    //   );
                                    //   loadSrc();
                                    //   refreshSink.add("");
                                  },
                                ),
                                InkWell(
                                  onTap: () async {
                                    Color? color = await pickColor(context);
                                    if (color != null) {
                                      // int hexColor = color.value;
                                      // property["value"] = "Color($hexColor)";
                                      // print(property["value"]);

                                      // screen["screen"][0] = setPropertyInTree(
                                      //   property,
                                      //   screen["screen"][0],
                                      // );
                                      // loadSrc();
                                      // refreshSink.add("");
                                    }
                                  },
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Pallet.inside1),
                                      borderRadius: BorderRadius.circular(5),
                                      color: (property.value != null)
                                          ? Color(int.parse(property.value))
                                          : Colors.white,
                                    ),
                                    // color: Colors.red,
                                  ),
                                ),
                              ],
                            )
                          // ],
                          // ),
                          //   else if (property["data_type"].toString().toLowerCase() ==
                          //       "icondata")
                          //     InkWell(
                          //       onTap: () async {
                          //         IconData icon = await pickIcon(context);
                          //         print(icon.fontFamily);
                          //         property["value"] =
                          //             "IconData(0x${icon.codePoint.toRadixString(16)}, fontFamily: '${icon.fontFamily}')";
                          //         screen["screen"][0] = setPropertyInTree(
                          //           property,
                          //           screen["screen"][0],
                          //         );
                          //         loadSrc();
                          //         refreshSink.add("");
                          //       },
                          //       child: Icon(
                          //         IconData(
                          //           int.parse(
                          //             property["value"]
                          //                 .toString()
                          //                 .splitFirst("IconData(")[1]
                          //                 .split(",")[0],
                          //           ),
                          //           fontFamily: 'MaterialIcons',
                          //         ),
                          //       ),
                          //     )
                          //   else if (property["data_type"].toString().toLowerCase() ==
                          //       "bool")
                          //     Checkbox(
                          //       value: property["value"] ?? false,
                          //       onChanged: (bool? value) {
                          //         print(value);
                          //         if (value == false) {
                          //           property["value"] = null;
                          //         } else {
                          //           property["value"] = "Color(4294967295)";
                          //         }
                          //         screen["screen"][0] = setPropertyInTree(
                          //           property,
                          //           screen["screen"][0],
                          //         );
                          //         loadSrc();
                          //         refreshSink.add("");
                          //       },
                          //     )
                          // else ...[
                          //     InkWell(
                          //       onTap: () {
                          //         if (property["is_code"] == true) {
                          //           property["is_code"] = false;
                          //         } else {
                          //           property["is_code"] = true;
                          //         }
                          //         screen["screen"][0] = setPropertyInTree(
                          //           property,
                          //           screen["screen"][0],
                          //         );
                          //         setState(() {});
                          //       },
                          //       child:
                          //           (property["is_code"] == true)
                          //               ? Icon(Icons.code, size: 18)
                          //               : Icon(Icons.edit, size: 15),
                          //     ),
                          //     SizedBox(width: 5),
                          //     if ((property["is_code"] == true))
                          //       SizedBox(
                          //         width: 120,
                          //         child: CodeTextBox(
                          //           text: property["value"] ?? "",
                          //           onType: (value) {
                          //             property["value"] = value;
                          //             screen["screen"][0] = setPropertyInTree(
                          //               property,
                          //               screen["screen"][0],
                          //             );
                          //           },
                          //         ),
                          //       )
                          else
                            SizedBox(
                              width:
                                  (property.xd_data_type == XDDataType.string)
                                  ? 80
                                  : 50,
                              child: TextBox(),
                            ),
                        SizedBox(width: 10),
                        InkWell(
                          onTap: () {},
                          child: Icon(Icons.more_vert, size: 15),
                        ),
                        // ],
                      ],
                    ),
                  ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Pallet.inside1),
                  ),
                ),
                Container(height: 1, color: Pallet.divider),
              ],
            ],
          ),
        );
      },
    );
  }

  side(Property property) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                property.xd_name,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Pallet.inside2,
                ),
                child: Row(
                  children: [
                    SideButton(
                      type: BorderType.all,
                      active: property.xd_state == "all",
                      onTap: () {
                        property.xd_state = "all";
                        final propertyController =
                            Get.find<PropertyController>();
                        propertyController.update();
                      },
                    ),
                    Container(width: 1, height: 15, color: Pallet.divider),
                    // SizedBox(width: 10),
                    SideButton(
                      type: BorderType.side,
                      active: property.xd_state == "side",
                      onTap: () {
                        property.xd_state = "side";
                        final propertyController =
                            Get.find<PropertyController>();
                        propertyController.update();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              if (property.xd_state == "all") ...[
                // SizedBox(width: 10),
                Text("all:  ", style: TextStyle(fontSize: 13)),
                SizedBox(
                  width: 40,
                  child: TextBox(
                    // small: true,
                    // controller: TextEditingController(text: ((property["value"] ?? [0, 0, 0, 0])[0]).toString()),
                    // onType: (value) {
                    //   // if (color != null) {
                    //   try {
                    //     List values = [0, 0, 0, 0];
                    //     for (var i = 0; i < values.length; i++) {
                    //       values[i] = int.parse(value);
                    //     }
                    //     property["value"] = values;
                    //     print("parp");
                    //     print(property);

                    //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                    //   } catch (e) {
                    //     print(e);
                    //   }

                    //   // }
                    // },
                  ),
                ),
              ] else ...[
                Text("t:  "),
                Expanded(
                  child: TextBox(
                    // small: true,
                    // controller: TextEditingController(text: ((property["value"] ?? [0, 0, 0, 0])[0]).toString()),
                    // onType: (value) {
                    //   print("kiar?");
                    //   try {
                    //     List values = [];
                    //     if (property["value"] == null) {
                    //       values = [0, 0, 0, 0];
                    //     } else {
                    //       values = property["value"];
                    //     }
                    //     values[0] = int.parse(value);
                    //     print(values);
                    //     property["value"] = values;
                    //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                    //     // print(jsonEncode(stack));
                    //   } catch (e) {
                    //     print(e);
                    //   }
                    // },
                  ),
                ),
                SizedBox(width: 10),
                Text("b:  "),
                Expanded(
                  child: TextBox(
                    // small: true,
                    // controller: TextEditingController(text: (property["value"] ?? [0, 0, 0, 0])[1].toString()),
                    // onType: (value) {
                    //   try {
                    //     List values = [];
                    //     if (property["value"] == null) {
                    //       values = [0, 0, 0, 0];
                    //     } else {
                    //       values = property["value"];
                    //     }
                    //     values[1] = int.parse(value);
                    //     print(values);
                    //     property["value"] = values;
                    //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                    //   } catch (e) {}
                    // },
                  ),
                ),
                SizedBox(width: 10),
                Text("l:  "),
                Expanded(
                  child: TextBox(
                    // small: true,
                    // controller: TextEditingController(text: (property["value"] ?? [0, 0, 0, 0])[2].toString()),
                    // onType: (value) {
                    //   try {
                    //     List values = [];
                    //     if (property["value"] == null) {
                    //       values = [0, 0, 0, 0];
                    //     } else {
                    //       values = property["value"];
                    //     }
                    //     values[2] = int.parse(value);
                    //     print(values);
                    //     property["value"] = values;
                    //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                    //   } catch (e) {}
                    // },
                  ),
                ),
                SizedBox(width: 10),
                Text("r:  "),
                Expanded(
                  child: TextBox(
                    // small: true,
                    // controller: TextEditingController(text: (property["value"] ?? [0, 0, 0, 0])[3].toString()),
                    // onType: (value) {
                    //   try {
                    //     List values = [];
                    //     if (property["value"] == null) {
                    //       values = [0, 0, 0, 0];
                    //     } else {
                    //       values = property["value"];
                    //     }
                    //     values[3] = int.parse(value);
                    //     print(values);
                    //     property["value"] = values;
                    //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                    //   } catch (e) {}
                    // },
                  ),
                ),
                SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  shadow(Property property) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                property.xd_name,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(width: 10),
              InkWell(
                onTap: () async {
                  // Color? color = await pickColor(context);
                  // if (color != null) {
                  //   int hexColor = color.value;
                  //   property["value"]["color"] = "Color($hexColor)";
                  //   screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                  //   // print(jsonEncode(stack));
                  //   loadSrc();
                  //   refreshSink.add("");
                  // }
                },
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    // color: Color(int.parse(property["value"]["color"].toString().removeCapsule("(", ""))),
                    // color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          Column(
            children: [
              Row(
                children: [
                  Text("x:  ", style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: TextBox(
                      // small: true,
                      // controller: TextEditingController(text: (property["value"]["x"].toString() ?? "0")),
                      // onType: (value) {
                      //   try {
                      //     property["value"]["x"] = value;
                      //     print("parp");
                      //     print(property);

                      //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                      //   } catch (e) {}
                      // },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("y:  ", style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: TextBox(
                      // small: true,
                      // controller: TextEditingController(text: (property["value"]["y"].toString())),
                      // onType: (value) {
                      //   try {
                      //     property["value"]["y"] = value;
                      //     print("parp");
                      //     print(property);

                      //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                      //   } catch (e) {}
                      // },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text("r:  ", style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: TextBox(
                      // small: true,
                      // controller: TextEditingController(text: (property["value"]["radius"].toString())),
                      // onType: (value) {
                      //   try {
                      //     property["value"]["radius"] = value;
                      //     print("parp");
                      //     print(property);

                      //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                      //   } catch (e) {}
                      // },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("s:  ", style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: TextBox(
                      // small: true,
                      // controller: TextEditingController(text: (property["value"]["spread"].toString())),
                      // onType: (value) {
                      //   try {
                      //     property["value"]["spread"] = value;
                      //     print("parp");
                      //     print(property);

                      //     screen["screen"][0] = setPropertyInTree(property, screen["screen"][0]);
                      //   } catch (e) {}
                      // },
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Expanded(
          //   child: Row(
          //     children: [
          //       Checkbox(
          //         value: property.value != null,
          //         onChanged: (bool? value) {
          //           //   print(value);
          //           //   if (value == false) {
          //           //     property["value"] = null;
          //           //   } else {
          //           //     property["value"] = "Color(4294967295)";
          //           //   }
          //           //   screen["screen"][0] = setPropertyInTree(
          //           //     property,
          //           //     screen["screen"][0],
          //           //   );
          //           //   loadSrc();
          //           //   refreshSink.add("");
          //         },
          //       ),
          //       InkWell(
          //         onTap: () async {
          //           // Color? color = await pickColor(context);
          //           // if (color != null) {
          //             // int hexColor = color.value;
          //             // property["value"] = "Color($hexColor)";
          //             // print(property["value"]);

          //             // screen["screen"][0] = setPropertyInTree(
          //             //   property,
          //             //   screen["screen"][0],
          //             // );
          //             // loadSrc();
          //             // refreshSink.add("");
          //           // }
          //         },
          //         child: Container(
          //           width: 18,
          //           height: 18,
          //           decoration: BoxDecoration(
          //             border: Border.all(color: Pallet.inside1),
          //             borderRadius: BorderRadius.circular(5),
          //             color: (property.value != null)
          //                 ? Color(int.parse(property.value))
          //                 : Colors.white,
          //           ),
          //           // color: Colors.red,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

enum BorderType { all, side }

class SideButton extends StatelessWidget {
  const SideButton({
    super.key,
    this.type = BorderType.all,
    this.active = false,
    required this.onTap,
  });
  final BorderType type;
  final bool active;
  final Function() onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          border: (type == BorderType.all)
              ? Border.all(color: active ? Colors.purple : Colors.grey)
              : null,
        ),
        child: Stack(
          children: [
            if (type == BorderType.side) ...[
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.5),
                  width: 10,
                  height: 1,
                  color: active ? Colors.purple : Colors.grey,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 2.5),
                  width: 1,
                  height: 10,
                  color: active ? Colors.purple : Colors.grey,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 2.5),
                  width: 1,
                  height: 10,
                  color: active ? Colors.purple : Colors.grey,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2.5),
                  width: 10,
                  height: 1,
                  color: active ? Colors.purple : Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
