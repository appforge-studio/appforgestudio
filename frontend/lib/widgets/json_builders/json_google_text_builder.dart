import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class JsonGoogleTextBuilder extends JsonWidgetBuilder {
  const JsonGoogleTextBuilder({required super.args});

  @override
  String get type => 'text';

  @override
  JsonWidgetBuilderModel createModel({
    ChildWidgetBuilder? childBuilder,
    required JsonWidgetData data,
  }) {
    final dynamic d = data;
    final Map<String, dynamic> args =
        d.values ?? d.map ?? d.json ?? d.args ?? {};

    return _JsonGoogleTextModel(
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
    final text = args['text']?.toString() ?? '';
    final styleMap = args['style'];
    final textAlignStr = args['textAlign'];

    TextStyle? style;
    if (styleMap != null) {
      final fontFamily = styleMap['fontFamily']?.toString();
      final fontSize = styleMap['fontSize'] is num
          ? (styleMap['fontSize'] as num).toDouble()
          : null;
      final colorStr = styleMap['color'];
      final fontWeightStr = styleMap['fontWeight'];

      Color? color;
      if (colorStr != null && colorStr is String) {
        try {
          // Generally handle #AARRGGBB or #RRGGBB
          // My component.dart produces #AARRGGBB
          if (colorStr.startsWith('#')) {
            String hex = colorStr.substring(1);
            if (hex.length == 6) hex = 'FF$hex'; // Assume opaque if 6 chars
            color = Color(int.parse(hex, radix: 16));
          }
        } catch (e) {
          debugPrint('Error parsing color: $e');
        }
      }

      FontWeight fontWeight = FontWeight.normal;
      if (fontWeightStr != null) {
        switch (fontWeightStr) {
          case 'w100':
            fontWeight = FontWeight.w100;
            break;
          case 'w200':
            fontWeight = FontWeight.w200;
            break;
          case 'w300':
            fontWeight = FontWeight.w300;
            break;
          case 'w400':
            fontWeight = FontWeight.w400;
            break;
          case 'w500':
            fontWeight = FontWeight.w500;
            break;
          case 'w600':
            fontWeight = FontWeight.w600;
            break;
          case 'w700':
            fontWeight = FontWeight.w700;
            break;
          case 'w800':
            fontWeight = FontWeight.w800;
            break;
          case 'w900':
            fontWeight = FontWeight.w900;
            break;
        }
      }

      if (fontFamily != null && fontFamily.isNotEmpty) {
        try {
          style = GoogleFonts.getFont(
            fontFamily,
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          );
        } catch (e) {
          debugPrint('GoogleFont not found: $fontFamily, falling back');
          style = TextStyle(
            fontFamily: fontFamily,
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          );
        }
      } else {
        style = TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
      }
    }

    TextAlign textAlign = TextAlign.start;
    if (textAlignStr != null) {
      switch (textAlignStr) {
        case 'left':
          textAlign = TextAlign.left;
          break;
        case 'right':
          textAlign = TextAlign.right;
          break;
        case 'center':
          textAlign = TextAlign.center;
          break;
        case 'justify':
          textAlign = TextAlign.justify;
          break;
        case 'start':
          textAlign = TextAlign.start;
          break;
        case 'end':
          textAlign = TextAlign.end;
          break;
      }
    }

    return Text(text, style: style, textAlign: textAlign, key: key);
  }
}

class _JsonGoogleTextModel extends JsonWidgetBuilderModel {
  const _JsonGoogleTextModel(
    super.args, {
    this.childBuilder,
    this.originalBuilder,
  });

  final ChildWidgetBuilder? childBuilder;
  final JsonWidgetBuilder? originalBuilder;

  @override
  Map<String, dynamic> toJson() => args;
}
