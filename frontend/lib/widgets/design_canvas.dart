import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import '../controllers/canvas_controller.dart';
import '../models/component_model.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../services/upload_service.dart';
import '../components/component_factory.dart';
import '../utilities/component_dimensions.dart';
import 'component_overlay_layer.dart';
import '../utilities/component_overlay_manager.dart';
import 'box_selection_overlay.dart';
import 'image_generator_dialog.dart';

class DesignCanvas extends StatefulWidget {
  const DesignCanvas({super.key});

  @override
  State<DesignCanvas> createState() => _DesignCanvasState();
}

class _DesignCanvasState extends State<DesignCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  final CanvasController canvasController = Get.find<CanvasController>();

  // Track last pointer position for manual panning
  Offset? _lastPanPosition;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _transformationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            canvasController.deleteSelectedComponents();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: (event) {
          _focusNode.requestFocus();
          if (event.buttons == kMiddleMouseButton) {
            _lastPanPosition = event.localPosition;
          } else if (event.buttons == kPrimaryButton) {
            final scenePos = _toScene(event.localPosition);

            // Check if we are interacting with a component (clicking on one)
            bool isOverComponent = false;
            // Iterate in reverse (top-most first)
            for (final component in canvasController.components.reversed) {
              final width =
                  ComponentDimensions.getWidth(component) ??
                  component.detectedSize?.width ??
                  100.0;
              final height =
                  ComponentDimensions.getHeight(component) ??
                  component.detectedSize?.height ??
                  100.0;

              // Add a small buffer for resize handles if needed, or stick to body
              // We expand the rect by 15.0 to account for resize handles/controls that may extend outside
              final rect = Rect.fromLTWH(
                component.x - 15.0,
                component.y - 15.0,
                width + 30.0,
                height + 30.0,
              );
              if (rect.contains(scenePos)) {
                isOverComponent = true;
                break;
              }
            }

            // Only start box selection if clicking on empty canvas
            if (!isOverComponent &&
                !canvasController.isInteractingWithComponent) {
              canvasController.startBoxSelection(scenePos);
            }
          }
        },
        onPointerMove: (event) {
          if (event.buttons == kMiddleMouseButton) {
            // Manual Panning
            if (_lastPanPosition != null) {
              final delta = event.localPosition - _lastPanPosition!;
              final currentMatrix = _transformationController.value;

              // Get the scale factor
              final scale = currentMatrix.getMaxScaleOnAxis();

              // For panning: when dragging right, content moves right
              // The translation in the matrix needs to be updated
              // Matrix4 stores translation in entry(0,3) for x and entry(1,3) for y
              final currentTx = currentMatrix.entry(0, 3);
              final currentTy = currentMatrix.entry(1, 3);

              // Add delta divided by scale to the translation
              final newMatrix = Matrix4.copy(currentMatrix)
                ..setEntry(0, 3, currentTx + delta.dx / scale)
                ..setEntry(1, 3, currentTy + delta.dy / scale);

              _transformationController.value = newMatrix;
              _lastPanPosition = event.localPosition;
            }
          } else if (event.buttons == kPrimaryButton &&
              canvasController.isBoxSelecting) {
            // Box Selection Update
            final scenePos = _toScene(event.localPosition);
            canvasController.updateBoxSelection(scenePos);
          }
        },
        onPointerUp: (event) {
          _lastPanPosition = null;
          if (canvasController.isBoxSelecting) {
            canvasController.endBoxSelection();
          }
        },
        onPointerCancel: (event) {
          _lastPanPosition = null;
          if (canvasController.isBoxSelecting) {
            canvasController.endBoxSelection();
          }
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(500),
          minScale: 0.1,
          maxScale: 5.0,
          constrained: false, // Allow the phone to take its natural size
          panEnabled: false, // DISABLE DEFAULT PAN
          child: Center(
            child: Obx(() {
              final canvasSize = canvasController.canvasSize;
              final isDragging = canvasController.isDragging;

              return Stack(
                alignment: Alignment.center,
                clipBehavior:
                    Clip.none, // Allow selection box to extend outside
                children: [
                  // Phone Background
                  SizedBox(
                    width: canvasSize.width + 30,
                    height: canvasSize.height,
                    child: Image.asset('assets/phone.png', fit: BoxFit.fill),
                  ),

                  // Canvas Area
                  DropTarget(
                    onDragDone: (details) async {
                      final canvasController = Get.find<CanvasController>();
                      final canvasSize = canvasController.canvasSize;

                      for (final file in details.files) {
                        final ext = file.name.split('.').last.toLowerCase();
                        if ([
                          'png',
                          'jpg',
                          'jpeg',
                          'webp',
                          'gif',
                        ].contains(ext)) {
                          debugPrint('📥 Dropped file: ${file.name}');

                          // Upload file
                          final url = await UploadService.uploadFile(file);

                          if (url != null) {
                            debugPrint('✅ File uploaded: $url');

                            // Calculate position
                            // We are inside the Canvas Area Container, so localPosition is relative to canvas
                            final x = details.localPosition.dx.clamp(
                              0.0,
                              canvasSize.width - 150,
                            );
                            final y = details.localPosition.dy.clamp(
                              0.0,
                              canvasSize.height - 150,
                            );

                            // Create component
                            final component = ComponentFactory.createComponent(
                              ComponentType.image,
                              x,
                              y,
                            );

                            // Update source URL
                            // ComponentProperties is immutable, so we update it
                            final updatedProperties = component.properties
                                .updateProperty('source', url);

                            final updatedComponent = component.copyWith(
                              properties: updatedProperties,
                            );

                            // Add to canvas
                            canvasController.addComponent(updatedComponent);
                          }
                        }
                      }
                    },
                    child: Container(
                      width: canvasSize.width,
                      height:
                          canvasSize.height -
                          30, // Keeping original height logic
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isDragging
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.grey[300]!,
                          width: isDragging ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Builder(
                          builder: (canvasContext) => MouseRegion(
                            cursor: canvasController.isResizingComponent
                                ? MouseCursor.defer
                                : _getCanvasCursor(
                                    canvasController,
                                    isDragging,
                                  ),
                            child: DragTarget<ComponentType>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) {
                                final componentType = details.data;
                                final RenderBox renderBox =
                                    canvasContext.findRenderObject()
                                        as RenderBox;
                                final localPosition = renderBox.globalToLocal(
                                  details.offset,
                                );
                                final constrainedX = localPosition.dx.clamp(
                                  0.0,
                                  canvasSize.width - 50,
                                );
                                final constrainedY = localPosition.dy.clamp(
                                  0.0,
                                  canvasSize.height - 50,
                                );
                                final newComponent =
                                    ComponentFactory.createComponent(
                                      componentType,
                                      constrainedX,
                                      constrainedY,
                                    );

                                if (componentType == ComponentType.image) {
                                  // For images, open the generator/upload dialog
                                  Get.dialog(const ImageGeneratorDialog()).then(
                                    (imageUrl) {
                                      if (imageUrl != null &&
                                          imageUrl is String) {
                                        final updatedProperties = newComponent
                                            .properties
                                            .updateProperty('source', imageUrl);
                                        final updatedComponent = newComponent
                                            .copyWith(
                                              properties: updatedProperties,
                                            );
                                        canvasController.onDragEnd(
                                          Offset(constrainedX, constrainedY),
                                          updatedComponent,
                                        );
                                      } else {
                                        // User cancelled or failed
                                        canvasController.onDragEnd(
                                          Offset.zero,
                                          null,
                                        );
                                      }
                                    },
                                  );
                                } else {
                                  canvasController.onDragEnd(
                                    Offset(constrainedX, constrainedY),
                                    newComponent,
                                  );
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                final showDropIndicator =
                                    candidateData.isNotEmpty;

                                return Stack(
                                  children: [
                                    // Drop zone indicator
                                    if (showDropIndicator)
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 2.0,
                                            style: BorderStyle.solid,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
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
                                    if (!showDropIndicator)
                                      _buildCanvasGuides(canvasSize),

                                    // Render existing components (visual only, no interactions)
                                    ...canvasController.components.map((
                                      component,
                                    ) {
                                      return _buildVisualComponentWidget(
                                        component,
                                      );
                                    }),

                                    // Overlay layer for all interactions (dragging, resizing, selection)
                                    ComponentOverlayLayer(
                                      canvasSize: canvasSize,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // BOX SELECTION OVERLAY (Figma-style) - Outside clipped area so it's always visible
                  if (canvasController.isBoxSelecting &&
                      canvasController.boxSelectionRect != null)
                    BoxSelectionOverlay(
                      rect: canvasController.boxSelectionRect!,
                    ),
                  Positioned(
                    top: 25,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Offset _toScene(Offset globalPos) {
    // Convert generic global position to the scene coordinates.
    // .toScene() accounts for the InteractiveViewer transformation.
    return _transformationController.toScene(globalPos);
  }

  Widget _buildVisualComponentWidget(ComponentModel component) {
    final width = ComponentDimensions.getWidth(component);
    final height = ComponentDimensions.getHeight(component);
    final canvasController = Get.find<CanvasController>();

    return Positioned(
      left: component.x,
      top: component.y,
      child: MeasuredWidget(
        componentId: component.id,
        child: Obx(() {
          final interaction = canvasController.getInteractionState(
            component.id,
          );

          double dx = 0;
          double dy = 0;
          double currentWidth = width ?? 0.0;
          double currentHeight = height ?? 0.0;

          if (interaction != null) {
            if (interaction.position != null) {
              dx = interaction.position!.dx - component.x;
              dy = interaction.position!.dy - component.y;
            }
            if (interaction.size != null) {
              currentWidth = interaction.size!.width;
              currentHeight = interaction.size!.height;
            }
          }

          Widget childWidget = _renderComponent(component);

          if (currentWidth > 0 || currentHeight > 0) {
            childWidget = SizedBox(
              width: currentWidth > 0 ? currentWidth : null,
              height: currentHeight > 0 ? currentHeight : null,
              child: childWidget,
            );
          }

          return Transform.translate(
            offset: Offset(dx, dy),
            child: childWidget,
          );
        }),
      ),
    );
  }

  Widget _renderComponent(ComponentModel component) {
    return Builder(
      builder: (BuildContext context) {
        try {
          final jsonSchema = component.jsonSchema;

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
          debugPrint('❌ ERROR rendering ${component.type.name} component: $e');
          return _buildErrorWidget(component, e.toString());
        }
      },
    );
  }

  Widget _buildErrorWidget(ComponentModel component, String error) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
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
      return ComponentOverlayManager.getCursor('copy');
    } else {
      return ComponentOverlayManager.getCursor('basic');
    }
  }

  Widget _buildCanvasGuides(Size canvasSize) {
    return CustomPaint(size: canvasSize, painter: CanvasGuidesPainter());
  }
}

/// A widget that measures its own size and reports it to the CanvasController
class MeasuredWidget extends StatefulWidget {
  final String componentId;
  final Widget child;

  const MeasuredWidget({
    super.key,
    required this.componentId,
    required this.child,
  });

  @override
  State<MeasuredWidget> createState() => _MeasuredWidgetState();
}

class _MeasuredWidgetState extends State<MeasuredWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
  }

  @override
  void didUpdateWidget(MeasuredWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSize());
  }

  void _measureSize() {
    if (!mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      Get.find<CanvasController>().updateComponentMeasuredSize(
        widget.componentId,
        renderBox.size,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class CanvasGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
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
      ..color = Colors.grey.withOpacity(0.2)
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
