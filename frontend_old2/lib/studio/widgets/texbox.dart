import 'package:flutter/material.dart';

import '../../globals.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      // style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12, // Reduced font size for typed text
      ),
      cursorHeight: 14, // Optional: adjust cursor height
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 0),
        filled: true,
        fillColor: Pallet.inside2,
        hintText: 'Search',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withOpacity(0.5),
          size: 15,
        ),
      ),
    );
  }
}

class TextBox extends StatelessWidget {
  const TextBox({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      // style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11, // Reduced font size for typed text
      ),
      cursorHeight: 12, // Optional: adjust cursor height
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        filled: true,
        fillColor: Pallet.inside2,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
