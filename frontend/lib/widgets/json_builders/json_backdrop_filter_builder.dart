import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class JsonBackdropFilterBuilder extends JsonWidgetBuilder {
  const JsonBackdropFilterBuilder({required super.args});

  @override
  String get type => JsonBackdropFilterSchema.id;

  @override
  JsonWidgetBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final dynamic d = data;
    final Map<String, dynamic> args =
        d.values ?? d.map ?? d.json ?? d.args ?? {};

    return _JsonBackdropFilterModel(
      args,
      childBuilder: childBuilder,
      originalBuilder: this,
    );
  }

  @override
  Widget buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  }) {
    final filterArgs = args['filter'] as Map<String, dynamic>?;
    final childArgs = args['child'];

    if (filterArgs == null || childArgs == null) {
      return const SizedBox();
    }

    // Parse filter parameters
    final filterType = filterArgs['type'] as String?;
    final sigmaX = (filterArgs['sigmaX'] as num?)?.toDouble() ?? 0.0;
    final sigmaY = (filterArgs['sigmaY'] as num?)?.toDouble() ?? 0.0;

    if (filterType != 'blur') {
      return const SizedBox();
    }

    // Build child widget directly
    Widget? child;
    try {
      final childWidgetData = JsonWidgetData.fromDynamic(
        childArgs,
        registry: JsonWidgetRegistry.instance,
      );
      child = childWidgetData.build(context: context);
    } catch (e) {
      debugPrint('Error building backdrop filter child: $e');
      return const SizedBox();
    }

    return BackdropFilter(
      key: key,
      filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
      child: child,
    );
  }
}

class _JsonBackdropFilterModel extends JsonWidgetBuilderModel {
  const _JsonBackdropFilterModel(
    super.args, {
    this.childBuilder,
    this.originalBuilder,
  });

  final ChildWidgetBuilder? childBuilder;
  final JsonWidgetBuilder? originalBuilder;

  @override
  Map<String, dynamic> toJson() => args;

  // Manual copyWith to avoid analyzer issues
  JsonWidgetBuilderModel copyWith({
    ChildWidgetBuilder? childBuilder,
    JsonWidgetData? data,
    JsonWidgetBuilder? originalBuilder,
  }) {
    dynamic d = data;
    return _JsonBackdropFilterModel(
      d?.values ?? d?.map ?? d?.json ?? d?.args ?? args,
      childBuilder: childBuilder ?? this.childBuilder,
      originalBuilder: originalBuilder ?? this.originalBuilder,
    );
  }
}

class JsonBackdropFilterSchema {
  static const id = 'backdrop_filter';

  static JsonWidgetBuilder? builder(
    Map<String, dynamic> args, {
    JsonWidgetRegistry? registry,
  }) {
    return JsonBackdropFilterBuilder(args: args);
  }
}
