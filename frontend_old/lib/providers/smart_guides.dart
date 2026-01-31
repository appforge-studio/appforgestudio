import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum GuideType {
  vertical,
  horizontal,
  centerVertical,
  centerHorizontal,
}

class SmartGuide {
  final GuideType type;
  final double position;
  final String sourceWidgetId;
  final String targetWidgetId;
  final Color color;

  SmartGuide({
    required this.type,
    required this.position,
    required this.sourceWidgetId,
    required this.targetWidgetId,
    this.color = Colors.blue,
  });
}

class SmartGuidesController extends GetxController {
  List<SmartGuide> _guides = [];
  List<SmartGuide> get guides => _guides;

  void showGuides(List<SmartGuide> guides) {
    _guides = guides;
    update();
  }

  void hideGuides() {
    _guides = [];
    update();
  }

  void addGuide(SmartGuide guide) {
    _guides = [..._guides, guide];
    update();
  }

  void clearGuides() {
    _guides = [];
    update();
  }
}

// Controller to store widget positions for alignment detection
class WidgetPositionsController extends GetxController {
  Map<String, Rect> _positions = {};
  Map<String, Rect> get positions => _positions;
  
  int _errorCount = 0;
  static const int _maxErrors = 10;

  void updatePosition(String widgetId, Rect position) {
    try {
      // Only update if the position has actually changed
      final currentPosition = _positions[widgetId];
      if (currentPosition == null || 
          currentPosition.left != position.left ||
          currentPosition.top != position.top ||
          currentPosition.width != position.width ||
          currentPosition.height != position.height) {
        _positions = {..._positions, widgetId: position};
        _errorCount = 0; // Reset error count on successful update
        update();
      }
    } catch (e) {
      _errorCount++;
      print('Error updating position for widget $widgetId: $e');
      if (_errorCount >= _maxErrors) {
        print('Too many errors, disabling smart guides position updates');
        return;
      }
    }
  }

  void removePosition(String widgetId) {
    try {
      if (_positions.containsKey(widgetId)) {
        final newState = Map<String, Rect>.from(_positions);
        newState.remove(widgetId);
        _positions = newState;
        update();
      }
    } catch (e) {
      print('Error removing position for widget $widgetId: $e');
    }
  }

  void clearPositions() {
    try {
      _positions = {};
      _errorCount = 0;
      update();
    } catch (e) {
      print('Error clearing positions: $e');
    }
  }

  void batchUpdatePositions(Map<String, Rect> newPositions) {
    try {
      // Batch update multiple positions at once to reduce rebuilds
      final updatedState = Map<String, Rect>.from(_positions);
      updatedState.addAll(newPositions);
      _positions = updatedState;
      _errorCount = 0; // Reset error count on successful update
      update();
    } catch (e) {
      _errorCount++;
      print('Error in batch update positions: $e');
      if (_errorCount >= _maxErrors) {
        print('Too many errors, disabling smart guides position updates');
        return;
      }
    }
  }
}

// Controller is initialized in providers.dart