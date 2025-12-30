// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_pannel/main.dart';

void main() {
  testWidgets('Admin panel loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AdminApp());

    // Verify that the admin panel loads with the correct title.
    expect(find.text('Vyom Admin - Dashboard'), findsOneWidget);
    expect(find.text('Welcome to Vyom Admin Panel'), findsOneWidget);

    // Verify that the drawer menu button is present.
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
