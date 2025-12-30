import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'visual_builder_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Note: All component interactions are now handled by the ComponentOverlayManager
  // Components are purely visual with no interaction logic in their JSON schemas

  debugPrint(
    '🚀 Starting app with ComponentOverlayManager handling all interactions',
  );

  // Disable the default browser context menu
  await BrowserContextMenu.disableContextMenu();

  // Use the full app
  runApp(const VisualBuilderApp());
}
