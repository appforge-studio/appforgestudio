import 'package:flutter/material.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class JsonImageBuilder extends JsonWidgetBuilder {
  const JsonImageBuilder({required super.args});

  @override
  String get type => JsonImageSchema.id;

  @override
  JsonWidgetBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final dynamic d = data;
    final Map<String, dynamic> args =
        d.values ?? d.map ?? d.json ?? d.args ?? {};

    return _JsonImageModel(
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
    final imageUrl = args['image'] as String?;
    final width = args['width'] as num?;
    final height = args['height'] as num?;
    final fitString = args['fit'] as String?;

    if (imageUrl == null || imageUrl.isEmpty) {
      return SizedBox(
        width: width?.toDouble(),
        height: height?.toDouble(),
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }

    BoxFit boxFit = BoxFit.cover;
    if (fitString != null) {
      try {
        boxFit = BoxFit.values.firstWhere((e) => e.name == fitString);
      } catch (_) {}
    }

    // Determine if it's a network image or asset
    // Simple heuristic: starts with http means network
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width?.toDouble(),
        height: height?.toDouble(),
        fit: boxFit,
        key: key,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image));
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      // Fallback to asset or file if valid
      return Image.asset(
        imageUrl,
        width: width?.toDouble(),
        height: height?.toDouble(),
        fit: boxFit,
        key: key,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }
  }
}

class _JsonImageModel extends JsonWidgetBuilderModel {
  const _JsonImageModel(super.args, {this.childBuilder, this.originalBuilder});

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
    return _JsonImageModel(
      d?.values ?? d?.map ?? d?.json ?? d?.args ?? args,
      childBuilder: childBuilder ?? this.childBuilder,
      originalBuilder: originalBuilder ?? this.originalBuilder,
    );
  }
}

class JsonImageSchema {
  static const id = 'image';

  static JsonWidgetBuilder? builder(
    Map<String, dynamic> args, {
    JsonWidgetRegistry? registry,
  }) {
    return JsonImageBuilder(args: args);
  }
}
