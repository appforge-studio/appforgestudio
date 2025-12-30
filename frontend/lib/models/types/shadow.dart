import 'package:flutter/material.dart';
import 'color.dart';

/// A class representing a shadow with color, offset, blur radius, and spread radius
class XDShadow {
  /// The color of the shadow
  final XDColor color;
  
  /// The offset of the shadow from the element
  final Offset offset;
  
  /// The blur radius of the shadow
  final double blurRadius;
  
  /// The spread radius of the shadow
  final double spreadRadius;

  /// Creates an XDShadow with the given properties
  const XDShadow({
    required this.color,
    required this.offset,
    required this.blurRadius,
    required this.spreadRadius,
  });

  /// Creates a simple shadow with basic parameters
  XDShadow.simple({
    required XDColor color,
    double dx = 0.0,
    double dy = 2.0,
    double blurRadius = 4.0,
    double spreadRadius = 0.0,
  }) : color = color,
       offset = Offset(dx, dy),
       blurRadius = blurRadius,
       spreadRadius = spreadRadius;

  /// Converts to Flutter BoxShadow
  BoxShadow toBoxShadow() {
    return BoxShadow(
      color: color.toColor(),
      offset: offset,
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    );
  }

  @override
  String toString() => 'XDShadow(color: $color, offset: $offset, blurRadius: $blurRadius, spreadRadius: $spreadRadius)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XDShadow &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          offset == other.offset &&
          blurRadius == other.blurRadius &&
          spreadRadius == other.spreadRadius;

  @override
  int get hashCode => Object.hash(color, offset, blurRadius, spreadRadius);
}