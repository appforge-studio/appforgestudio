import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import '../controllers/canvas_controller.dart';
import '../models/component_model.dart';
import '../models/enums.dart';
import '../utilities/component_factory.dart';
import '../utilities/component_dimensions.dart';
import '../models/types/color.dart';
import 'component_overlay_layer.dart';
import '../utilities/component_overlay_manager.dart';

class DesignCanvas extends StatelessWidget {
  const DesignCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final canvasController = Get.find<CanvasController>();

    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Obx(() {
          final canvasSize = canvasController.canvasSize;
          final isDragging = canvasController.isDragging;

          return Container(
            width: canvasSize.width,
            height: canvasSize.height,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isDragging
                    ? Colors.blue.withValues(alpha: 0.5)
                    : Colors.grey[300]!,
                width: isDragging ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Builder(
              builder: (canvasContext) => MouseRegion(
                cursor: canvasController.isResizingComponent
                    ? MouseCursor
                          .defer // Let child MouseRegions handle cursor
                    : _getCanvasCursor(canvasController, isDragging),
                child: DragTarget<ComponentType>(
                  onWillAcceptWithDetails: (details) => true,
                  onAcceptWithDetails: (details) {
                    final componentType = details.data;

                    // Convert global position to local canvas position
                    final RenderBox renderBox =
                        canvasContext.findRenderObject() as RenderBox;
                    final localPosition = renderBox.globalToLocal(
                      details.offset,
                    );

                    // Constrain position within canvas bounds
                    final constrainedX = localPosition.dx.clamp(
                      0.0,
                      canvasSize.width - 50,
                    );
                    final constrainedY = localPosition.dy.clamp(
                      0.0,
                      canvasSize.height - 50,
                    );

                    final newComponent = ComponentFactory.createComponent(
                      componentType,
                      constrainedX,
                      constrainedY,
                    );

                    canvasController.onDragEnd(
                      Offset(constrainedX, constrainedY),
                      newComponent,
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    final showDropIndicator = candidateData.isNotEmpty;

                    return Stack(
                      children: [
                        // Drop zone indicator
                        if (showDropIndicator)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.blue,
                                width: 2.0,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_circle_outline,
                                size: 48,
                                color: Colors.blue,
                              ),
                            ),
                          ),

                        // Canvas boundaries indicator (subtle grid or guides)
                        if (!showDropIndicator) _buildCanvasGuides(canvasSize),

                        // Render existing components (visual only, no interactions)
                        ...canvasController.components.map((component) {
                          return _buildVisualComponentWidget(component);
                        }),

                        // Overlay layer for all interactions (dragging, resizing, selection)
                        // IMPORTANT: This must be LAST (on top) to capture gestures
                        ComponentOverlayLayer(canvasSize: canvasSize),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Build visual-only component widget (no interactions)
  Widget _buildVisualComponentWidget(ComponentModel component) {
    // Get dimensions or null if properties are disabled
    final width = ComponentDimensions.getWidth(component);
    final height = ComponentDimensions.getHeight(component);

    // Get canvas content from controller for context awareness
    final controller = Get.find<CanvasController>();
    final canvasSize = controller.canvasSize;

    // If dimensions are null (disabled property), take up full available space
    // relative to the component's position
    final effectiveWidth =
        width ?? (canvasSize.width - component.x).clamp(0.0, canvasSize.width);
    final effectiveHeight =
        height ??
        (canvasSize.height - component.y).clamp(0.0, canvasSize.height);

    return Positioned(
      left: component.x,
      top: component.y,
      child: SizedBox(
        width: effectiveWidth,
        height: effectiveHeight,
        child: _renderComponent(component),
      ),
    );
  }

  Widget _renderComponent(ComponentModel component) {
    return Builder(
      builder: (BuildContext context) {
        try {
          // For text components, use a direct Flutter Text widget as fallback
          if (component.type == ComponentType.text) {
            return _renderTextComponentDirect(component);
          }

          // Use json_dynamic_widget to render from the component's jsonSchema
          final jsonSchema = component.jsonSchema;

          debugPrint(
            '🎨 ${component.type.name.toUpperCase()} COMPONENT JSON SCHEMA: $jsonSchema',
          );

          // Create a JsonWidgetData from the schema
          final widgetData = JsonWidgetData.fromDynamic(
            jsonSchema,
            registry: JsonWidgetRegistry.instance,
          );

          // Build the widget using json_dynamic_widget
          final widget = widgetData.build(
            context: context,
            registry: JsonWidgetRegistry.instance,
          );

          return widget;
        } catch (e) {
          // Error handling - show fallback widget with error indication
          debugPrint('❌ ERROR rendering ${component.type.name} component: $e');
          return _buildErrorWidget(component, e.toString());
        }
      },
    );
  }

  /// Direct Flutter Text widget rendering for text components
  Widget _renderTextComponentDirect(ComponentModel component) {
    final content =
        component.properties.getProperty<String>('content') ?? 'Sample Text';
    final fontSize =
        component.properties.getProperty<double>('fontSize') ?? 16.0;
    final color =
        component.properties.getProperty<XDColor>('color')?.toColor() ??
        Colors.black;
    final alignment =
        component.properties.getProperty<TextAlign>('alignment') ??
        TextAlign.left;
    final fontWeight =
        component.properties.getProperty<FontWeight>('fontWeight') ??
        FontWeight.normal;
    final fontFamily =
        component.properties.getProperty<String>('fontFamily') ?? 'Roboto';

    return Container(
      width: ComponentDimensions.getWidth(component),
      height: ComponentDimensions.getHeight(component),
      alignment: _getAlignmentFromTextAlign(alignment),
      child: Text(
        content,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
        ),
        textAlign: alignment,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  /// Convert TextAlign to Alignment for Container
  Alignment _getAlignmentFromTextAlign(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.justify:
        return Alignment.centerLeft;
    }
  }

  Widget _buildErrorWidget(ComponentModel component, String error) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 24),
          const SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            component.type.name,
            style: TextStyle(color: Colors.red, fontSize: 10),
          ),
        ],
      ),
    );
  }

  SystemMouseCursor _getCanvasCursor(
    CanvasController controller,
    bool isDragging,
  ) {
    if (controller.isDraggingComponent) {
      return ComponentOverlayManager.getCursor('grabbing');
    } else if (controller.isResizingComponent) {
      return ComponentOverlayManager.getCursor(controller.resizeHandle);
    } else if (isDragging) {
      return ComponentOverlayManager.getCursor(
        'copy',
      ); // When dragging from component panel
    } else {
      return ComponentOverlayManager.getCursor('basic');
    }
  }

  Widget _buildCanvasGuides(Size canvasSize) {
    return CustomPaint(size: canvasSize, painter: CanvasGuidesPainter());
  }
}

class CanvasGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // Draw subtle grid lines every 50 pixels
    for (double x = 0; x <= size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw center lines
    final centerPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // Vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );

    // Horizontal center line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
