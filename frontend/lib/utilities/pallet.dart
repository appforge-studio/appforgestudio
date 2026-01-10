import 'package:flutter/material.dart';

class Pallet {
  static bool light = false;

  static Color background = Color(0xFF121212);
  static Color insideFont = Colors.white;
  static Color divider = Color(0xFF21242A);

  static Color font1 = Color(0xFFf9f9fb);
  static Color font2 = Color(0xFFececed);
  static Color font3 = Color(0xFFbebebe);

  static Color inside1 = Color(0xFF16151a);
  static Color inside2 = Color(0xFF181428);
  static Color inside3 = Color(0xFF7363E0);

  static darkMode() {
    Pallet.background = Color(0xFF161819);
    Pallet.insideFont = Colors.white;

    Pallet.font1 = Color(0xFFf9f9fb);
    Pallet.font2 = Color(0xFFececed);
    Pallet.font3 = Color(0xFFbebebe);

    Pallet.inside1 = Color(0xFF323337);
    Pallet.inside2 = Color(0xFF27292D);
    Pallet.inside3 = Color(0xFF1d1f20);
  }

  static lightMode() {
    Pallet.background = Color(0xFFf5f7fb);
    Pallet.insideFont = Colors.white;

    Pallet.font1 = Color(0xFF464646);
    Pallet.font2 = Color(0xFF5c5c5c);
    Pallet.font3 = Color(0xFFa2a2a2);

    Pallet.inside1 = Color(0xFFffffff);
    Pallet.inside2 = Color(0xFFe3e3e5);
    Pallet.inside3 = Color(0xFFf5f7fb);
  }
}
