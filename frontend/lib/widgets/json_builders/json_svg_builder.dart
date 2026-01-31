import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class JsonSvgBuilder extends JsonWidgetBuilder {
  const JsonSvgBuilder({required super.args});

  @override
  String get type => JsonSvgSchema.id;

  @override
  JsonWidgetBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    // Dynamic cast to bypass analyzer errors regarding JsonWidgetData properties
    final dynamic d = data;
    final Map<String, dynamic> args =
        d.values ?? d.map ?? d.json ?? d.args ?? {};

    return _JsonSvgModel(
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
    final svgData = args['data'] as String?;
    final colorHex = args['color'] as String?;
    final width = args['width'] as num?;
    final height = args['height'] as num?;

    if (svgData == null || svgData.isEmpty) {
      return SizedBox.shrink(key: key);
    }

    Color? color;
    if (colorHex != null) {
      try {
        // Handle #AARRGGBB or #RRGGBB
        String hex = colorHex.replaceFirst('#', '');
        if (hex.length == 6) {
          hex = 'FF$hex';
        }
        color = Color(int.parse(hex, radix: 16));
      } catch (e) {
        debugPrint('Error parsing color in JsonSvgBuilder: $e');
      }
    }

    return SvgPicture.string(
      svgData,
      key: key,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      width: width?.toDouble(),
      height: height?.toDouble(),
    );
  }
}

class _JsonSvgModel extends JsonWidgetBuilderModel {
  const _JsonSvgModel(super.args, {this.childBuilder, this.originalBuilder});

  final ChildWidgetBuilder? childBuilder;
  final JsonWidgetBuilder? originalBuilder;

  @override
  Map<String, dynamic> toJson() => args;

  // copyWith probably not inherited or signature differs, so removing @override to allow custom implementation
  JsonWidgetBuilderModel copyWith({
    ChildWidgetBuilder? childBuilder,
    JsonWidgetData? data,
    JsonWidgetBuilder? originalBuilder,
  }) {
    dynamic d = data;
    return _JsonSvgModel(
      d?.values ?? d?.map ?? d?.json ?? d?.args ?? args,
      childBuilder: childBuilder ?? this.childBuilder,
      originalBuilder: originalBuilder ?? this.originalBuilder,
    );
  }
}

class JsonSvgSchema {
  static const id = 'svg';

  static JsonWidgetBuilder? builder(
    Map<String, dynamic> args, {
    JsonWidgetRegistry? registry,
  }) {
    return JsonSvgBuilder(args: args);
  }
}
