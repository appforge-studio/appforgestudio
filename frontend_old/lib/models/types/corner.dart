import 'package:flutter/material.dart';

/// Enum representing different corner radius application modes
enum CornerType {
  /// Apply radius to all corners
  all,
  /// Apply radius to specific corners
  corner,
}

/// A class representing corner radius with 4 values (topLeft, topRight, bottomRight, bottomLeft)
class XDCorner {
  /// The corner radius values in order: [topLeft, topRight, bottomRight, bottomLeft]
  final List<double> values;

  /// The type of corner radius application
  final CornerType type;

  /// Creates an XDCorner with the given values and type
  const XDCorner({
    required this.values,
    this.type = CornerType.corner,
  }) : assert(values.length == 4, 'Corner values must contain exactly 4 elements');

  /// Creates uniform corner radius for all corners
  XDCorner.all(double value)
      : values = [value, value, value, value],
        type = CornerType.all;

  /// Creates corner radius with individual corner values
  XDCorner.corners({
    double topLeft = 0.0,
    double topRight = 0.0,
    double bottomRight = 0.0,
    double bottomLeft = 0.0,
  }) : values = [topLeft, topRight, bottomRight, bottomLeft],
       type = CornerType.corner;

  /// Gets the top-left corner radius value
  double get topLeft => values[0];

  /// Gets the top-right corner radius value
  double get topRight => values[1];

  /// Gets the bottom-right corner radius value
  double get bottomRight => values[2];

  /// Gets the bottom-left corner radius value
  double get bottomLeft => values[3];

  /// Converts to Flutter BorderRadius
  BorderRadius toBorderRadius() {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomRight: Radius.circular(bottomRight),
      bottomLeft: Radius.circular(bottomLeft),
    );
  }

  @override
  String toString() => 'XDCorner(values: $values, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XDCorner &&
          runtimeType == other.runtimeType &&
          values.toString() == other.values.toString() &&
          type == other.type;

  @override
  int get hashCode => Object.hash(values, type);
}