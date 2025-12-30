// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:appforge/visual_builder_app.dart';

void main() {
  testWidgets('Visual Builder app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VisualBuilderApp());

    // Verify that our app loads with the expected title.
    expect(find.text('Visual Builder'), findsOneWidget);
    
    // Verify that the PropertyEditor shows the default message when no component is selected
    expect(find.text('Select a component to edit properties'), findsOneWidget);
  });
}
