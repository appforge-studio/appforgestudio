import 'package:flutter/material.dart';
import 'package:frontend/globals.dart';
import 'src/colorpicker.dart';
import 'src/palette.dart';

Future<Color?> pickColor(
  BuildContext context, {
  Color initialColor = Colors.white,
}) async {
  Color selectedColor = initialColor;
  final TextEditingController hexController = TextEditingController();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Pallet.background,
            title: Text('Pick a color!', style: TextStyle(color: Pallet.font1)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (value) {
                      setState(() => selectedColor = value);
                    },
                    enableAlpha: true, // Show alpha slider
                    hexInputBar: true, // Show hex input field
                    hexInputController: hexController,
                    labelTypes: [
                      ColorLabelType.rgb,
                      ColorLabelType.hsv,
                      ColorLabelType.hsl,
                    ], // Show color values
                    showLabel: true,
                  ),
                  // Opacity percentage display
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Opacity:  ${(selectedColor.opacity * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Got it'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
  return selectedColor;
}
