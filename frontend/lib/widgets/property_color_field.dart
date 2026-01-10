import 'package:appforge/widgets/color_picker/colorpicker.dart';
import 'package:appforge/widgets/color_picker/palette.dart';
import 'package:flutter/material.dart';
import '../models/types/color.dart';
import '../utilities/pallet.dart';

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

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$label:",
            style: TextStyle(fontSize: 13, color: Pallet.font1),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showColorPicker(context, currentColor);
            },
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Pallet.inside2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        bottomLeft: Radius.circular(5),
                      ),
                      border: Border(right: BorderSide(color: Pallet.divider)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        _colorToHex(currentColor),
                        style: TextStyle(fontSize: 13, color: Pallet.font1),
                      ),
                    ),
                  ),
                ],
              ),
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
                final newXDColor = XDColor([hexString], type: ColorType.solid);
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
