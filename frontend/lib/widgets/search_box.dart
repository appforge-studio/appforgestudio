import 'package:flutter/material.dart';
import '../utilities/pallet.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: Colors.white70,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      cursorHeight: 14,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        filled: true,
        fillColor: Pallet.inside2,
        hintText: 'Search',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withOpacity(0.5),
          size: 15,
        ),
      ),
    );
  }
}

