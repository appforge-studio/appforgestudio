import 'package:google_fonts/google_fonts.dart';

import '../studio/studio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'globals.dart';
import 'widgets/xd.dart';
import 'providers/providers.dart';

void main() {
  xd.init();
  // Initialize all controllers before running the app
  initializeControllers();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Appforge',
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansTextTheme(
          TextTheme(
            displayMedium: TextStyle(color: Pallet.font1),
            displayLarge: TextStyle(color: Pallet.font1),
            bodyMedium: TextStyle(color: Pallet.font1),
            bodyLarge: TextStyle(color: Pallet.font1),
            titleMedium: TextStyle(color: Pallet.font1),
          ),
        ),
        iconTheme: IconThemeData(color: Pallet.font2),
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Studio(),
    );
  }
}
