import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/types/color.dart';

class PropertyColorField extends StatelessWidget {
  final String label;
  final XDColor value;
  final ValueChanged<XDColor> onChanged;

  const PropertyColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentColor = value.toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _showColorPicker(context, currentColor);
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                    ),
                    border: Border(right: BorderSide(color: Colors.grey[300]!)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _colorToHex(currentColor),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, Color currentColor) {
    Color pickerColor = currentColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (Color color) {
                pickerColor = color;
              },
              enableAlpha: true,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                final hexString = _colorToHex(pickerColor);
                final newXDColor = XDColor(
                  [hexString],
                  type: ColorType.solid,
                );
                onChanged(newXDColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
