import 'package:flutter/material.dart';
import '../providers/smart_guides.dart';
import 'debouncer.dart';

class SmartGuidesService {
  static const double _snapThreshold = 8.0; // Distance in pixels to snap to alignment
  static final Debouncer _updateDebouncer = Debouncer(delay: const Duration(milliseconds: 16)); // ~60fps
  
  /// Detects alignments between the dragged widget and other widgets
  static List<SmartGuide> detectAlignments(
    String draggedWidgetId,
    Rect draggedWidgetRect,
    Map<String, Rect> otherWidgets,
  ) {
    final List<SmartGuide> guides = [];
    
    for (final entry in otherWidgets.entries) {
      final targetWidgetId = entry.key;
      final targetRect = entry.value;
      
      if (targetWidgetId == draggedWidgetId) continue;
      
      // Check edge alignments
      _checkEdgeAlignments(draggedWidgetRect, targetRect, draggedWidgetId, targetWidgetId, guides);
      
      // Check center alignments
      _checkCenterAlignments(draggedWidgetRect, targetRect, draggedWidgetId, targetWidgetId, guides);
    }
    
    return guides;
  }
  
  /// Check for edge-to-edge alignments
  static void _checkEdgeAlignments(
    Rect draggedRect,
    Rect targetRect,
    String draggedId,
    String targetId,
    List<SmartGuide> guides,
  ) {
    // Left edge alignments
    if ((draggedRect.left - targetRect.left).abs() <= _snapThreshold) {
      guides.add(SmartGuide(
        type: GuideType.vertical,
        position: targetRect.left,
        sourceWidgetId: draggedId,
        targetWidgetId: targetId,
        color: Colors.blue,
      ));
    }
    
    // Right edge alignments
    if ((draggedRect.right - targetRect.right).abs() <= _snapThreshold) {
      guides.add(SmartGuide(
        type: GuideType.vertical,
        position: targetRect.right,
        sourceWidgetId: draggedId,
        targetWidgetId: targetId,
        color: Colors.blue,
      ));
    }
    
    // Top edge alignments
    if ((draggedRect.top - targetRect.top).abs() <= _snapThreshold) {
      guides.add(SmartGuide(
        type: GuideType.horizontal,
        position: targetRect.top,
        sourceWidgetId: draggedId,
        targetWidgetId: targetId,
        color: Colors.blue,
      ));
    }
    
    // Bottom edge alignments
    if ((draggedRect.bottom - targetRect.bottom).abs() <= _snapThreshold) {
      guides.add(SmartGuide(
        type: GuideType.horizontal,
        position: targetRect.bottom,
        sourceWidgetId: draggedId,
        targetWidgetId: targetId,
        color: Colors.blue,
      ));
    }
  }
  
  /// Check for center alignments
  static void _checkCenterAlignments(
    Rect draggedRect,
    Rect targetRect,
    String draggedId,
    String targetId,
    List<SmartGuide> guides,
  ) {
    final draggedCenterX = draggedRect.left + draggedRect.width / 2;
    final draggedCenterY = draggedRect.top + draggedRect.height / 2;
    final targetCenterX = targetRect.left + targetRect.width / 2;
    final targetCenterY = targetRect.top + targetRect.height / 2;
    
    // Vertical center alignment
    if ((draggedCenterX - targetCenterX).abs() <= _snapThreshold) {
      guides.add(SmartGuide(
        type: GuideType.centerVertical,
        position: targetCenterX,
        sourceWidgetId: draggedId,
        targetWidgetId: targetId,
        color: Colors.green,
      ));
    }
    
    // Horizontal center alignment
    if ((draggedCenterY - targetCenterY).abs() <= _snapThreshold) {
      guides.add(SmartGuide(
        type: GuideType.centerHorizontal,
        position: targetCenterY,
        sourceWidgetId: draggedId,
        targetWidgetId: targetId,
        color: Colors.green,
      ));
    }
  }
  
  /// Snap the dragged widget to the nearest alignment
  static Offset snapToAlignment(
    Offset currentPosition,
    List<SmartGuide> guides,
    Size widgetSize,
  ) {
    if (guides.isEmpty) return currentPosition;
    
    double snappedX = currentPosition.dx;
    double snappedY = currentPosition.dy;
    
    for (final guide in guides) {
      switch (guide.type) {
        case GuideType.vertical:
          snappedX = guide.position;
          break;
        case GuideType.horizontal:
          snappedY = guide.position;
          break;
        case GuideType.centerVertical:
          snappedX = guide.position - widgetSize.width / 2;
          break;
        case GuideType.centerHorizontal:
          snappedY = guide.position - widgetSize.height / 2;
          break;
      }
    }
    
    return Offset(snappedX, snappedY);
  }
  
  /// Get the current position of a widget based on its margin
  static Rect getWidgetRect(Offset position, Size size) {
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }
  
  /// Convert margin to position
  static Offset marginToPosition(List<double> margin) {
    return Offset(margin[2], margin[0]); // left, top
  }
  
  /// Convert position to margin
  static List<double> positionToMargin(Offset position) {
    return [position.dy, 0.0, position.dx, 0.0]; // top, bottom, left, right
  }
  
  /// Debounced update function to prevent too frequent updates
  static void debouncedUpdate(VoidCallback callback) {
    _updateDebouncer.run(callback);
  }
} 