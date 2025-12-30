import 'package:flutter/material.dart';

/// Enum representing different padding application modes
enum SideType {
  /// Apply padding to all sides
  all,
  /// Apply padding to specific sides
  side,
}

/// A class representing padding with 4 values (top, right, bottom, left)
class XDSide {
  /// The padding values in order: [top, right, bottom, left]
  final List<double> values;
  
  /// The type of padding application
  final SideType type;

  /// Creates an XDSide with the given values and type
  const XDSide({
    required this.values,
    this.type = SideType.side,
  }) : assert(values.length == 4, 'Padding values must contain exactly 4 elements');

  /// Creates uniform padding for all sides
  XDSide.all(double value) 
      : values = [value, value, value, value],
        type = SideType.all;

  /// Creates padding with individual side values
  XDSide.sides({
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
    double left = 0.0,
  }) : values = [top, right, bottom, left],
       type = SideType.side;

  /// Gets the top padding value
  double get top => values[0];

  /// Gets the right padding value
  double get right => values[1];

  /// Gets the bottom padding value
  double get bottom => values[2];

  /// Gets the left padding value
  double get left => values[3];

  /// Converts to Flutter EdgeInsets
  EdgeInsets toEdgeInsets() {
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  @override
  String toString() => 'XDSide(values: $values, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XDSide &&
          runtimeType == other.runtimeType &&
          values.toString() == other.values.toString() &&
          type == other.type;

  @override
  int get hashCode => Object.hash(values, type);
}