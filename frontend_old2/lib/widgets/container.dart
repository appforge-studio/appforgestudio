import 'package:dynamic_widget/dynamic_widget.dart';
import 'package:dynamic_widget/dynamic_widget/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../globals.dart';
import '../providers/providers.dart';
import '../providers/smart_guides.dart';
import '../utils/smart_guides_service.dart';
import 'resizable_widget.dart';
import 'draggable_widget.dart';
import 'dart:convert';
// import 'package:xd/xd.dart';
import 'package:xd/xd.dart';

class XDContainer extends WidgetParser {
  @override
  String get widgetName => "XDContainer";

  @override
  Widget parse(
    Map<String, dynamic> map,
    BuildContext buildContext,
    ClickListener? listener,
  ) {
    Widget containerWidget = Container(
      width: map['width']?.toDouble(),
      height: map['height']?.toDouble(),
      decoration: BoxDecoration(
        color: map.containsKey('color')
            ? parseHexColor(map['color'])
            : const Color(0xFFe3e2de),
        boxShadow: map.containsKey('shadow')
            ? [
                BoxShadow(
                  color: parseHexColor(map['shadow']['color'])!,
                  blurRadius: map['shadow']['radius'],
                  spreadRadius: map['shadow']['spread'],
                  offset: Offset(map['shadow']['x'], map['shadow']['y']),
                ),
              ]
            : null,
        borderRadius: map.containsKey('radius')
            ? BorderRadius.circular(map['radius'][0])
            : null,
      ),
      padding: map.containsKey('padding')
          ? EdgeInsets.only(
              top: (map['padding'][0] ?? 0.0).clamp(0.0, double.infinity),
              bottom: (map['padding'][1] ?? 0.0).clamp(0.0, double.infinity),
              left: (map['padding'][2] ?? 0.0).clamp(0.0, double.infinity),
              right: (map['padding'][3] ?? 0.0).clamp(0.0, double.infinity),
            )
          : null,
      margin: (map.containsKey('margin') && selectedWidget != map["id"])
          ? EdgeInsets.only(
              top: (map['margin'][0] ?? 0.0).clamp(0.0, double.infinity),
              bottom: (map['margin'][1] ?? 0.0).clamp(0.0, double.infinity),
              left: (map['margin'][2] ?? 0.0).clamp(0.0, double.infinity),
              right: (map['margin'][3] ?? 0.0).clamp(0.0, double.infinity),
            )
          : null,
      alignment: map.containsKey('align') ? parseAlignment(map['align']) : null,
      child: map.containsKey('child')
          ? (map['child']["type"] == "XDLayout")
                ? DynamicWidgetBuilder.buildFromMap(
                    map['child'],
                    buildContext,
                    listener,
                  )
                : Stack(
                    children: [
                      DynamicWidgetBuilder.buildFromMap(
                        map['child'],
                        buildContext,
                        listener,
                      )!,
                    ],
                  )
          : DragTarget<Component>(
              onAcceptWithDetails: (DragTargetDetails<Component> details) {
                droppingWidget = "";
                Map data = {
                  "id": map['id'],
                  "event": "onDrop",
                  "data": details.data.toJson(),
                };
                listener?.onClicked(jsonEncode(data));
              },
              onWillAcceptWithDetails: (details) {
                droppingWidget = map["id"];
                return true;
              },
              onLeave: (details) {
                droppingWidget = "";
                refreshSink.add("");
              },
              builder: (context, candidate, rejected) {
                if (droppingWidget == map["id"]) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Center(
                      child: Icon(Icons.abc, color: Colors.green),
                    ),
                  );
                }

                return Container(color: Colors.white);
              },
            ),
    );

    // Register widget position for smart guides using Consumer widget
    if (map.containsKey('margin') && map.containsKey('id')) {
      containerWidget = _PositionTracker(
        widgetId: map['id'],
        margin: List<double>.from(map['margin']),
        width: map['width']?.toDouble() ?? 200.0,
        height: map['height']?.toDouble() ?? 100.0,
        child: containerWidget,
      );
    }

    // Wrap with appropriate widget based on selection state
    if (selectedWidget == map["id"]) {
      // Selected widget: use both DraggableWidget and ResizableWidget for full functionality
      return DraggableWidget(
        widgetId: map['id'],
        listener: listener,
        // width: map['width']?.toDouble() ?? 200.0,
        // height: map['height']?.toDouble() ?? 100.0,
        margin: map['margin'] != null
            ? List<double>.from(map['margin'])
            : [0.0, 0.0, 0.0, 0.0],
        child: ResizableWidget(
          widgetId: map['id'],
          listener: listener,
          width: map['width']?.toDouble() ?? 200.0,
          height: map['height']?.toDouble() ?? 100.0,
          child: GestureDetector(
            onTap: () async {
              await selectWidget(map['id']);
            },
            child: containerWidget,
          ),
        ),
      );
    } else {
      // Non-selected widget: wrap with GestureDetector to enable selection
      return GestureDetector(
        onTap: () async {
          await selectWidget(map['id']);
        },
        child: containerWidget,
      );
    }
  }

  @override
  Map<String, dynamic>? export(Widget? widget, BuildContext? buildContext) {
    // TODO: implement export
    throw UnimplementedError();
  }

  @override
  Type get widgetType => throw UnimplementedError();
}

// Separate widget to handle position tracking
class _PositionTracker extends StatefulWidget {
  final String widgetId;
  final List<double> margin;
  final double width;
  final double height;
  final Widget child;

  const _PositionTracker({
    required this.widgetId,
    required this.margin,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  State<_PositionTracker> createState() => _PositionTrackerState();
}

class _PositionTrackerState extends State<_PositionTracker> {
  @override
  void initState() {
    super.initState();
    _updatePosition();
  }

  @override
  void didUpdateWidget(_PositionTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.margin != widget.margin ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _updatePosition();
    }
  }

  void _updatePosition() {
    try {
      final position = SmartGuidesService.marginToPosition(widget.margin);
      final widgetRect = SmartGuidesService.getWidgetRect(
        position,
        Size(widget.width, widget.height),
      );
      final widgetPositionsController = Get.find<WidgetPositionsController>();
      widgetPositionsController.updatePosition(widget.widgetId, widgetRect);
    } catch (e) {
      // Silently handle any errors to prevent crashes
      print('Error updating position for widget ${widget.widgetId}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
