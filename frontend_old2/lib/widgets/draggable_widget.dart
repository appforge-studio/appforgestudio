import 'dart:convert';
import 'package:dynamic_widget/dynamic_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../providers/smart_guides.dart';
import '../utils/smart_guides_service.dart';

Offset? dragStart;
List<double>? dragStartMargin;
Offset? dragStartLocal;

class DraggableWidget extends StatefulWidget {
  final String widgetId;
  final Widget child;
  final List<double>? margin; // [top, bottom, left, right]
  final ClickListener? listener;
  final bool showBorder; // New parameter to show selection border

  const DraggableWidget({
    super.key,
    required this.widgetId,
    required this.child,
    this.margin,
    this.listener,
    this.showBorder = false, // Default to false
  });

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  @override
  Widget build(BuildContext context) {
    final margin = widget.margin ?? [0.0, 0.0, 0.0, 0.0];

    Widget contentWidget = widget.child;
    
    // Add selection border if showBorder is true
    if (widget.showBorder) {
      contentWidget = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: contentWidget,
      );
    }

    // Wrap with IntrinsicWidth and IntrinsicHeight to auto-size based on child
    contentWidget = IntrinsicWidth(
      child: IntrinsicHeight(
        child: contentWidget,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: margin[0],
        bottom: margin[1],
        left: margin[2],
        right: margin[3],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          print('Pan start');
          dragStart = details.globalPosition;
          dragStartLocal = details.localPosition;
          dragStartMargin = List<double>.from(margin);
          
          // Update widget position in the provider for smart guides
          try {
            // Get the size from the RenderBox
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final size = renderBox.size;
            
            final currentPosition = SmartGuidesService.marginToPosition(margin);
            final widgetRect = SmartGuidesService.getWidgetRect(
              currentPosition, 
              size
            );
            final widgetPositionsController = Get.find<WidgetPositionsController>();
            widgetPositionsController.updatePosition(widget.widgetId, widgetRect);
          } catch (e) {
            print('Error updating position on pan start: $e');
          }
        },
        onPanUpdate: (details) {
          if (dragStart == null ||
              dragStartMargin == null ||
              dragStartLocal == null)
            return;
          // Calculate delta in local coordinates
          final localDelta = details.localPosition - dragStartLocal!;
          List<double> newMargin = List<double>.from(dragStartMargin!);
          newMargin[0] = (dragStartMargin![0] + localDelta.dy).clamp(
            0.0,
            1000.0,
          );
          newMargin[2] = (dragStartMargin![2] + localDelta.dx).clamp(
            0.0,
            1000.0,
          );
          
          // Update widget position for smart guides detection
          try {
            // Get the size from the RenderBox
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final size = renderBox.size;
            
            final currentPosition = SmartGuidesService.marginToPosition(newMargin);
            final widgetRect = SmartGuidesService.getWidgetRect(
              currentPosition, 
              size
            );
            final widgetPositionsController = Get.find<WidgetPositionsController>();
            widgetPositionsController.updatePosition(widget.widgetId, widgetRect);
            
            // Detect alignments and show smart guides
            final otherWidgets = widgetPositionsController.positions;
            final alignments = SmartGuidesService.detectAlignments(
              widget.widgetId,
              widgetRect,
              otherWidgets,
            );
            final smartGuidesController = Get.find<SmartGuidesController>();
            smartGuidesController.showGuides(alignments);
            
            // Snap to alignment if guides are present
            if (alignments.isNotEmpty) {
              final snappedPosition = SmartGuidesService.snapToAlignment(
                currentPosition,
                alignments,
                size,
              );
              newMargin = SmartGuidesService.positionToMargin(snappedPosition);
            }
          } catch (e) {
            print('Error updating position during pan: $e');
          }
          
          final marginEvent = {
            "event": "onMarginChange",
            "id": widget.widgetId,
            "data": {"margin": newMargin},
          };
          widget.listener?.onClicked(jsonEncode(marginEvent));
        },
        onPanEnd: (details) {
          dragStart = null;
          dragStartLocal = null;
          dragStartMargin = null;
          
          // Hide smart guides when dragging ends
          try {
            final smartGuidesController = Get.find<SmartGuidesController>();
            smartGuidesController.hideGuides();
          } catch (e) {
            print('Error hiding guides on pan end: $e');
          }
        },
        child: contentWidget,
      ),
    );
  }
} 