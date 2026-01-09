import 'dart:convert';

import 'package:xd/xd.dart';
import 'package:dynamic_widget/dynamic_widget.dart';
import 'package:dynamic_widget/dynamic_widget/utils.dart';
import 'package:flutter/material.dart';
import '../providers/providers.dart';

class XDLayout extends WidgetParser {
  @override
  String get widgetName => "XDLayout";
  bool dropping = false;
  @override
  Widget parse(
    Map<String, dynamic> map,
    BuildContext buildContext,
    ClickListener? listener,
  ) {
    build_layout() {
      // if (map["type"] == "XDLayoutType.listview") {
      //   return ListView(
      //     padding:
      //         map.containsKey('padding')
      //             ? EdgeInsets.only(
      //               top: map['padding'][0],
      //               bottom: map['padding'][1],
      //               left: map['padding'][2],
      //               right: map['padding'][3],
      //             )
      //             : EdgeInsets.zero,
      //     scrollDirection:
      //         map.containsKey('padding')
      //             ? parseAxis(map["padding"])
      //             : Axis.vertical,
      //     children: [
      //       for (var child in map['children'] ?? [])
      //         DynamicWidgetBuilder.buildFromMap(child, buildContext, listener)!,
      //     ],
      //   );
      // }

      return Padding(
        padding: map.containsKey('padding')
            ? EdgeInsets.only(
                top: map['padding'][0],
                bottom: map['padding'][1],
                left: map['padding'][2],
                right: map['padding'][3],
              )
            : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: map.containsKey('crossAxisAlignment')
              ? parseCrossAxisAlignment(map["crossAxisAlignment"])
              : CrossAxisAlignment.start,
          mainAxisAlignment: map.containsKey('mainAxisAlignment')
              ? parseMainAxisAlignment(map["mainAxisAlignment"])
              : MainAxisAlignment.start,
          children: [
            if (dropping)
              Container(
                width: 200,
                height: 2,
                decoration: BoxDecoration(color: Colors.green),
              ),
            for (var child in map['children'] ?? [])
              DynamicWidgetBuilder.buildFromMap(child, buildContext, listener)!,
            Expanded(child: Container(color: Colors.transparent)),
          ],
        ),
      );
    }

    Widget layoutWidget = Container(
      color: Color(0xFFf1f0ee),
      child: DragTarget<Component>(
        onAcceptWithDetails: (DragTargetDetails<Component> details) {
          dropping = false;
          Map data = {
            "id": map['id'],
            "event": "onDrop",
            "data": details.data.toJson(),
          };
          listener?.onClicked(jsonEncode(data));
        },
        onWillAcceptWithDetails: (details) {
          print("kiar");
          dropping = true;
          // refreshSink.add("");
          return true;
        },
        onLeave: (details) {
          dropping = false;
        },
        builder: (context, candidate, rejected) {
          return build_layout();
        },
      ),
    );

    // Add selection border and drag/resize functionality if selected
    // if (selectedWidget == map["id"]) {
    //   return DraggableWidget(
    //     widgetId: map['id'],
    //     listener: listener,
    //     margin: map['margin'] != null
    //         ? List<double>.from(map['margin'])
    //         : [0.0, 0.0, 0.0, 0.0],
    //     showBorder: true, // Show selection border
    //     child: layoutWidget,
    //   );
    // } else {
    // Non-selected: allow selection on tap
    return GestureDetector(
      onTap: () async {
        await selectWidget(map['id']);
      },
      child: layoutWidget,
    );
    // }
  }

  @override
  Map<String, dynamic>? export(Widget? widget, BuildContext? buildContext) {
    // TODO: implement export
    throw UnimplementedError();
  }

  @override
  // TODO: implement widgetType
  Type get widgetType => throw UnimplementedError();
}
