import 'package:dynamic_widget/dynamic_widget.dart';
import 'package:dynamic_widget/dynamic_widget/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/widgets/draggable_widget.dart';
import '../providers/providers.dart';
import '../providers/smart_guides.dart';
import '../utils/smart_guides_service.dart';

class XDText extends WidgetParser {
  @override
  String get widgetName => "XDText";

  @override
  Widget parse(
    Map<String, dynamic> map,
    BuildContext buildContext,
    ClickListener? listener,
  ) {
    Widget textWidget = Text(
      map.containsKey('text') ? map['text'] : "Text",
      style: TextStyle(
        fontSize: map.containsKey('size') ? map['size']?.toDouble() : 16.0,
        color: map.containsKey('color')
            ? parseHexColor(map['color'])
            : Colors.black,
        fontWeight: map.containsKey('weight')
            ? parseFontWeight(map['weight'])
            : FontWeight.normal,
      ),
    );

    // Register widget position for smart guides using Consumer widget
    if (map.containsKey('margin') && map.containsKey('id')) {
      textWidget = _PositionTracker(
        widgetId: map['id'],
        margin: List<double>.from(map['margin']),
        child: textWidget,
      );
    }

    // Wrap with appropriate widget based on selection state
    if (selectedWidget == map["id"]) {
      // Selected widget: use DraggableWidget for dragging functionality with border
      return DraggableWidget(
        widgetId: map['id'],
        listener: listener,
        margin: map['margin'] != null
            ? List<double>.from(map['margin'])
            : [0.0, 0.0, 0.0, 0.0],
        showBorder: true, // Show selection border for text
        child: textWidget,
      );
    } else {
      // Non-selected widget: only allow selection, no dragging
      return GestureDetector(
        onTap: () async {
          await selectWidget(map['id']);
        },
        child: Padding(
          padding: map.containsKey('margin')
              ? EdgeInsets.only(
                  top: map['margin'][0],
                  bottom: map['margin'][1],
                  left: map['margin'][2],
                  right: map['margin'][3],
                )
              : EdgeInsets.zero,
          child: textWidget,
        ),
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
  final Widget child;

  const _PositionTracker({
    required this.widgetId,
    required this.margin,
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
    if (oldWidget.margin != widget.margin) {
      _updatePosition();
    }
  }

  void _updatePosition() {
    try {
      final position = SmartGuidesService.marginToPosition(widget.margin);
      final widgetRect = SmartGuidesService.getWidgetRect(
        position,
        Size(100.0, 50.0), // Assuming a default size for position tracking
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
