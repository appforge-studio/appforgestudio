import 'package:flutter/material.dart';

/// Enum representing different color types
enum ColorType {
  /// Solid color
  solid,

  /// Linear gradient
  linear,

  /// Radial gradient
  radial,

  /// Sweep gradient
  sweep,
}

/// A class representing a color with a hash value that can be converted to a Flutter Color
class XDColor {
  /// The color values as a list of hash strings (e.g., ["#FF5733", "#33FF57"])
  final List<String> value;

  /// The type of color (solid, linear, radial, sweep)
  final ColorType type;

  /// The gradient stops as a list of numbers (0.0 to 1.0)
  final List<double> stops;

  /// The gradient begin alignment
  final Alignment begin;

  /// The gradient end alignment
  final Alignment end;

  /// Creates an XDColor with the given color values, type, stops, begin, and end
  const XDColor(
    this.value, {
    this.type = ColorType.solid,
    this.stops = const [],
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  /// Converts the first color value to a Flutter Color object
  Color toColor() {
    if (value.isEmpty) return Colors.black;

    String colorString = value.first;

    // Remove the hash symbol if present
    if (colorString.startsWith('#')) {
      colorString = colorString.substring(1);
    }

    // Ensure we have a valid 6 or 8 character hex string
    if (colorString.length == 6) {
      // Add full opacity if not specified
      colorString = 'FF$colorString';
    } else if (colorString.length != 8) {
      // Default to black if invalid format
      colorString = 'FF000000';
    }

    // Parse the hex string to integer and create Color
    return Color(int.parse(colorString, radix: 16));
  }

  /// Converts all color values to a list of Flutter Color objects
  List<Color> toColors() {
    return value.map((colorValue) {
      String colorString = colorValue;

      // Remove the hash symbol if present
      if (colorString.startsWith('#')) {
        colorString = colorString.substring(1);
      }

      // Ensure we have a valid 6 or 8 character hex string
      if (colorString.length == 6) {
        // Add full opacity if not specified
        colorString = 'FF$colorString';
      } else if (colorString.length != 8) {
        // Default to black if invalid format
        colorString = 'FF000000';
      }

      // Parse the hex string to integer and create Color
      return Color(int.parse(colorString, radix: 16));
    }).toList();
  }

  @override
  String toString() =>
      'XDColor($value, type: $type, stops: $stops, begin: $begin, end: $end)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XDColor &&
          runtimeType == other.runtimeType &&
          value.toString() == other.value.toString() &&
          type == other.type &&
          stops.toString() == other.stops.toString() &&
          begin == other.begin &&
          end == other.end;

  @override
  int get hashCode => Object.hash(value, type, stops, begin, end);
}
