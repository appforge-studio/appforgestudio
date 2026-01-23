import 'package:flutter/material.dart';
import 'types/side.dart';
import 'types/corner.dart';
import 'types/color.dart';

// Helper function to convert Color to int for JSON serialization
int colorToInt(Color color) => color.toARGB32();

class Enabled {
  final bool show;
  final bool enabled;

  const Enabled({required this.show, required this.enabled});

  Map<String, dynamic> toJson() => {'show': show, 'enabled': enabled};

  factory Enabled.fromJson(Map<String, dynamic> json) {
    return Enabled(
      show: json['show'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Enabled copyWith({bool? show, bool? enabled}) {
    return Enabled(show: show ?? this.show, enabled: enabled ?? this.enabled);
  }
}

// Base property class that all properties inherit from
abstract class Property {
  final String key;
  final String displayName;
  final String group;
  final PropertyType type;
  final Enabled enable;

  const Property({
    required this.key,
    required this.displayName,
    this.group = 'General',
    required this.type,
    this.enable = const Enabled(show: false, enabled: false),
  });

  // Convert property value to JSON
  dynamic toJson();

  // Create property from JSON
  Property fromJson(dynamic value);

  // Get the current value
  dynamic get value;

  // Create a copy with new value
  Property copyWith({dynamic value, Enabled? enable, String? group});
}

enum PropertyType {
  string,
  number,
  color,
  boolean,
  dropdown,
  side,
  corner,
  alignment,
  fontWeight,
  boxFit,
  icon,
}

// String property implementation
class StringProperty extends Property {
  final String _value;

  const StringProperty({
    required super.key,
    required super.displayName,
    super.group,
    required String value,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.string);

  @override
  String get value => _value;

  @override
  @override
  dynamic toJson() => {
    'value': _value,
    'enable': enable.toJson(),
    'group': group,
  };

  @override
  StringProperty fromJson(dynamic jsonValue) {
    String val = '';
    Enabled en = enable;
    String grp = group;

    if (jsonValue is Map<String, dynamic> && jsonValue.containsKey('enable')) {
      val = jsonValue['value']?.toString() ?? '';
      en = Enabled.fromJson(jsonValue['enable']);
      grp = jsonValue['group']?.toString() ?? group;
    } else {
      val = jsonValue?.toString() ?? '';
    }

    return StringProperty(
      key: key,
      displayName: displayName,
      group: grp,
      value: val,
      enable: en,
    );
  }

  @override
  StringProperty copyWith({dynamic value, Enabled? enable, String? group}) {
    return StringProperty(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: value?.toString() ?? _value,
      enable: enable ?? this.enable,
    );
  }
}

// Number property implementation
class NumberProperty extends Property {
  final double _value;
  final double? min;
  final double? max;

  const NumberProperty({
    required super.key,
    required super.displayName,
    super.group,
    required double value,
    this.min,
    this.max,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.number);

  @override
  double get value => _value;

  @override
  @override
  dynamic toJson() => {
    'value': _value,
    'enable': enable.toJson(),
    'group': group,
  };

  @override
  NumberProperty fromJson(dynamic jsonValue) {
    // Note: dynamic jsonValue can be double or Map
    double val = _value;
    Enabled en = enable;
    String grp = group;

    if (jsonValue is Map<String, dynamic> && jsonValue.containsKey('enable')) {
      final innerValue = jsonValue['value'];
      if (innerValue is num) {
        val = innerValue.toDouble();
      } else if (innerValue is String) {
        val = double.tryParse(innerValue) ?? _value;
      }
      en = Enabled.fromJson(jsonValue['enable']);
      grp = jsonValue['group']?.toString() ?? group;
    } else if (jsonValue is num) {
      val = jsonValue.toDouble();
    } else if (jsonValue is String) {
      val = double.tryParse(jsonValue) ?? _value;
    }

    if (min != null && val < min!) val = min!;
    if (max != null && val > max!) val = max!;

    return NumberProperty(
      key: key,
      displayName: displayName,
      group: grp,
      value: val,
      min: min,
      max: max,
      enable: en,
    );
  }

  @override
  NumberProperty copyWith({dynamic value, Enabled? enable, String? group}) {
    double val = (value is num) ? value.toDouble() : _value;
    if (min != null && val < min!) val = min!;
    if (max != null && val > max!) val = max!;

    return NumberProperty(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: val,
      min: min,
      max: max,
      enable: enable ?? this.enable,
    );
  }
}

// Color property implementation
class ComponentColorProperty extends Property {
  final XDColor _value;

  const ComponentColorProperty({
    required super.key,
    required super.displayName,
    super.group,
    required XDColor value,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.color);

  @override
  XDColor get value => _value;

  @override
  Map<String, dynamic> toJson() => {
    'value': _value.value,
    'type': _value.type.index,
    'stops': _value.stops,
    'begin': _value.begin,
    'end': _value.end,
    'enable': enable.toJson(),
    'group': group,
  };

  @override
  ComponentColorProperty fromJson(dynamic jsonValue) {
    XDColor val = _value;
    Enabled en = enable;
    String grp = group;

    if (jsonValue is Map<String, dynamic>) {
      if (jsonValue.containsKey('enable')) {
        en = Enabled.fromJson(jsonValue['enable']);
      }
      grp = jsonValue['group']?.toString() ?? group;

      List<String> colorValues = _value.value;
      ColorType type = _value.type;
      List<double> stops = _value.stops;
      Alignment begin = _value.begin;
      Alignment end = _value.end;

      final innerValue = jsonValue['value'];
      if (innerValue is List) {
        colorValues = innerValue.map((e) => e.toString()).toList();
      } else if (innerValue is String) {
        colorValues = [innerValue];
        type = ColorType.solid;
      }

      if (jsonValue['type'] is int) {
        int typeIndex = jsonValue['type'] as int;
        if (typeIndex >= 0 && typeIndex < ColorType.values.length) {
          type = ColorType.values[typeIndex];
        }
      }

      if (jsonValue['stops'] is List) {
        stops = (jsonValue['stops'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      val = XDColor(
        colorValues,
        type: type,
        stops: stops,
        begin: begin,
        end: end,
      );
    } else if (jsonValue is String) {
      // Handle hex string (e.g., "#FF0000" or "#AARRGGBB")
      val = XDColor(
        [jsonValue],
        type: ColorType.solid,
        stops: [],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return ComponentColorProperty(
      key: key,
      displayName: displayName,
      group: grp,
      value: val,
      enable: en,
    );
  }

  @override
  ComponentColorProperty copyWith({
    dynamic value,
    Enabled? enable,
    String? group,
  }) {
    return ComponentColorProperty(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: value is XDColor ? value : _value,
      enable: enable ?? this.enable,
    );
  }
}

// Boolean property implementation
class BooleanProperty extends Property {
  final bool _value;

  const BooleanProperty({
    required super.key,
    required super.displayName,
    super.group,
    required bool value,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.boolean);

  @override
  bool get value => _value;

  @override
  dynamic toJson() => {
    'value': _value,
    'enable': enable.toJson(),
    'group': group,
  };

  @override
  BooleanProperty fromJson(dynamic jsonValue) {
    bool val = _value;
    Enabled en = enable;
    String grp = group;

    if (jsonValue is Map<String, dynamic> && jsonValue.containsKey('enable')) {
      val = jsonValue['value'] as bool? ?? _value;
      en = Enabled.fromJson(jsonValue['enable']);
      grp = jsonValue['group']?.toString() ?? group;
    } else if (jsonValue is bool) {
      val = jsonValue;
    }

    return BooleanProperty(
      key: key,
      displayName: displayName,
      group: grp,
      value: val,
      enable: en,
    );
  }

  @override
  BooleanProperty copyWith({dynamic value, Enabled? enable, String? group}) {
    return BooleanProperty(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: value is bool ? value : _value,
      enable: enable ?? this.enable,
    );
  }
}

// Dropdown property implementation for enums
class DropdownProperty<T> extends Property {
  final T _value;
  final List<T> options;
  final String Function(T) displayText;

  const DropdownProperty({
    required super.key,
    required super.displayName,
    super.group,
    required T value,
    required this.options,
    required this.displayText,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.dropdown);

  @override
  T get value => _value;

  @override
  dynamic toJson() {
    dynamic val;
    if (_value is Enum) {
      val = (_value as Enum).index;
    } else {
      val = _value.toString();
    }
    return {'value': val, 'enable': enable.toJson(), 'group': group};
  }

  @override
  DropdownProperty<T> fromJson(dynamic jsonValue) {
    T newValue = _value;
    Enabled en = enable;
    String grp = group;
    dynamic innerValue = jsonValue;

    if (jsonValue is Map<String, dynamic> && jsonValue.containsKey('enable')) {
      innerValue = jsonValue['value'];
      en = Enabled.fromJson(jsonValue['enable']);
      grp = jsonValue['group']?.toString() ?? group;
    }

    if (_value is Enum && innerValue is int) {
      // Handle enum by index
      if (innerValue >= 0 && innerValue < options.length) {
        newValue = options[innerValue];
      }
    } else if (innerValue != null) {
      // Try to find matching option
      for (T option in options) {
        if (option.toString() == innerValue.toString()) {
          newValue = option;
          break;
        }
      }
    }

    return DropdownProperty<T>(
      key: key,
      displayName: displayName,
      group: grp,
      value: newValue,
      options: options,
      displayText: displayText,
      enable: en,
    );
  }

  @override
  DropdownProperty<T> copyWith({
    dynamic value,
    Enabled? enable,
    String? group,
  }) {
    return DropdownProperty<T>(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: value is T ? value : _value,
      options: options,
      displayText: displayText,
      enable: enable ?? this.enable,
    );
  }
}

// Side property implementation (formerly PaddingProperty)
class SideProperty extends Property {
  final XDSide _value;

  const SideProperty({
    required super.key,
    required super.displayName,
    super.group,
    required XDSide value,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.side);

  @override
  XDSide get value => _value;

  @override
  Map<String, dynamic> toJson() => {
    'values': _value.values,
    'type': _value.type.index,
    'enable': enable.toJson(),
    'group': group,
  };

  @override
  SideProperty fromJson(dynamic jsonValue) {
    XDSide val = _value;
    Enabled en = enable;
    String grp = group;

    if (jsonValue is Map<String, dynamic>) {
      if (jsonValue.containsKey('enable')) {
        en = Enabled.fromJson(jsonValue['enable']);
      }
      grp = jsonValue['group']?.toString() ?? group;

      List<double> values = _value.values;
      SideType type = _value.type;

      if (jsonValue['values'] is List) {
        values = (jsonValue['values'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      if (jsonValue['type'] is int) {
        int typeIndex = jsonValue['type'] as int;
        if (typeIndex >= 0 && typeIndex < SideType.values.length) {
          type = SideType.values[typeIndex];
        }
      }

      val = XDSide(values: values, type: type);
    }

    return SideProperty(
      key: key,
      displayName: displayName,
      group: grp,
      value: val,
      enable: en,
    );
  }

  @override
  SideProperty copyWith({dynamic value, Enabled? enable, String? group}) {
    return SideProperty(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: value is XDSide ? value : _value,
      enable: enable ?? this.enable,
    );
  }
}

// Corner property implementation
class CornerProperty extends Property {
  final XDCorner _value;

  const CornerProperty({
    required super.key,
    required super.displayName,
    super.group,
    required XDCorner value,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.corner);

  @override
  XDCorner get value => _value;

  @override
  Map<String, dynamic> toJson() => {
    'values': _value.values,
    'type': _value.type.index,
    'enable': enable.toJson(),
    'group': group,
  };

  @override
  CornerProperty fromJson(dynamic jsonValue) {
    XDCorner val = _value;
    Enabled en = enable;
    String grp = group;

    if (jsonValue is Map<String, dynamic>) {
      if (jsonValue.containsKey('enable')) {
        en = Enabled.fromJson(jsonValue['enable']);
      }
      grp = jsonValue['group']?.toString() ?? group;

      List<double> values = _value.values;
      CornerType type = _value.type;

      if (jsonValue['values'] is List) {
        values = (jsonValue['values'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      if (jsonValue['type'] is int) {
        int typeIndex = jsonValue['type'] as int;
        if (typeIndex >= 0 && typeIndex < CornerType.values.length) {
          type = CornerType.values[typeIndex];
        }
      }

      val = XDCorner(values: values, type: type);
    }

    return CornerProperty(
      key: key,
      displayName: displayName,
      group: grp,
      value: val,
      enable: en,
    );
  }

  @override
  CornerProperty copyWith({dynamic value, Enabled? enable, String? group}) {
    return CornerProperty(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: value is XDCorner ? value : _value,
      enable: enable ?? this.enable,
    );
  }
}

// Icon property implementation
class IconProperty extends Property {
  final String _value;

  const IconProperty({
    required super.key,
    required super.displayName,
    super.group,
    required String value,
    super.enable,
  }) : _value = value,
       super(type: PropertyType.icon);

  @override
  String get value => _value;

  @override
  dynamic toJson() => {
    'value': _value,
    'enable': enable.toJson(),
    'group': group,
  };

  @override
  IconProperty fromJson(dynamic jsonValue) {
    String val = _value;
    Enabled en = enable;
    String grp = group;

    if (jsonValue is Map<String, dynamic> && jsonValue.containsKey('enable')) {
      val = jsonValue['value']?.toString() ?? _value;
      en = Enabled.fromJson(jsonValue['enable']);
      grp = jsonValue['group']?.toString() ?? group;
    } else if (jsonValue is String) {
      val = jsonValue;
    }

    return IconProperty(
      key: key,
      displayName: displayName,
      group: grp,
      value: val,
      enable: en,
    );
  }

  @override
  IconProperty copyWith({dynamic value, Enabled? enable, String? group}) {
    return IconProperty(
      key: key,
      displayName: displayName,
      group: group ?? this.group,
      value: value?.toString() ?? _value,
      enable: enable ?? this.enable,
    );
  }
}
