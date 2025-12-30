import 'package:flutter/material.dart';

import '../components/component_factory.dart';
import 'component_properties.dart';

abstract class ComponentModel {
  final String id;
  final ComponentType type;
  double x;
  double y;
  final ComponentProperties properties;
  final bool resizable;
  Size? detectedSize; // Intrinsic size reported by the visual layer

  ComponentModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.properties,
    this.resizable = true,
  });

  Map<String, dynamic> toJson();
  Map<String, dynamic> get jsonSchema;
  ComponentModel copyWith({
    double? x,
    double? y,
    ComponentProperties? properties,
    bool? resizable,
  });
}
