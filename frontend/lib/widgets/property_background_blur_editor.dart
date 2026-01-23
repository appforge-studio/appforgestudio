import 'package:flutter/material.dart';
import '../models/component_properties.dart';
import '../utilities/pallet.dart';

class PropertyBackgroundBlurEditor extends StatelessWidget {
  final ComponentProperties properties;
  final Function(ComponentProperties) onChanged;

  const PropertyBackgroundBlurEditor({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Extract values
    final backgroundBlur =
        properties.getProperty<double>('backgroundBlur') ?? 0.0;
    final backgroundBlurOpacity =
        properties.getProperty<double>('backgroundBlurOpacity') ?? 1.0;
    final isEnabled = backgroundBlur > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Toggle Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Label
            SizedBox(
              width: 80,
              child: Text(
                "Bg Blur",
                style: TextStyle(
                  fontSize: 13,
                  color: Pallet.font1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),

            // Checkbox (shown when property is enabled)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: isEnabled,
                  onChanged: (val) {
                    if (val == true) {
                      _updateValue(
                        'backgroundBlur',
                        10.0,
                      ); // Enable with default value
                    } else {
                      _updateValue('backgroundBlur', 0.0); // Disable
                    }
                  },
                  activeColor: Pallet.inside3,
                  checkColor: Colors.white,
                  side: BorderSide(color: Pallet.font2, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (isEnabled) ...[
          const SizedBox(height: 12),
          // Blur Slider
          _SliderField(
            label: "Blur",
            value: backgroundBlur,
            min: 0.0,
            max: 50.0,
            onChanged: (val) => _updateValue('backgroundBlur', val),
          ),
          const SizedBox(height: 8),
          // Opacity Slider
          _SliderField(
            label: "Opacity",
            value: backgroundBlurOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: (val) => _updateValue('backgroundBlurOpacity', val),
          ),
        ],
      ],
    );
  }

  void _updateValue(String key, dynamic value) {
    if (value != null) {
      onChanged(properties.updateProperty(key, value));
    }
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Pallet.font2)),
            Text(
              value.toStringAsFixed(label == "Opacity" ? 2 : 1),
              style: TextStyle(fontSize: 11, color: Pallet.font1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Pallet.inside3,
            inactiveTrackColor: Pallet.inside2,
            thumbColor: Pallet.inside3,
            overlayColor: Pallet.inside3.withOpacity(0.2),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
