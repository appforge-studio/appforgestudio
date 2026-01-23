import 'package:flutter/material.dart';
import '../models/component_properties.dart';
import '../models/types/color.dart';
import '../utilities/pallet.dart';
import 'property_color_field.dart';

class PropertyShadowEditor extends StatelessWidget {
  final ComponentProperties properties;
  final Function(ComponentProperties) onChanged;

  const PropertyShadowEditor({
    super.key,
    required this.properties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Extract values
    final hasShadow = properties.getProperty<bool>('shadow') ?? false;
    final shadowColor =
        properties.getProperty<XDColor>('shadowColor') ??
        XDColor(['#33000000']);
    final shadowBlur = properties.getProperty<double>('shadowBlur') ?? 8.0;
    final shadowSpread = properties.getProperty<double>('shadowSpread') ?? 0.0;
    final shadowX = properties.getProperty<double>('shadowX') ?? 0.0;
    final shadowY = properties.getProperty<double>('shadowY') ?? 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Toggle + Color Logic
        // We want to combine the "Shadow" label (which usually comes from the boolean property)
        // with the color picker on the same row, similar to inheritance or grouping.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Toggle for Shadow
            SizedBox(
              width: 80,
              child: Text(
                "Shadow",
                style: TextStyle(
                  fontSize: 13,
                  color: Pallet.font1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Color Picker on the right (looks like legacy)
            const Spacer(),

            // Checkbox (Enable/Disable) - Moved to left of Color Picker
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: hasShadow,
                  onChanged: (val) => _updateValue('shadow', val),
                  activeColor: Pallet.inside3,
                  checkColor: Colors.white,
                  side: BorderSide(color: Pallet.font2, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Color Picker on the right
            InkWell(
              onTap: () {
                // Open color picker logic matching PropertyColorField behavior
                // We can reuse PropertyColorField logic if we wrap it or extract it.
              },
              child: PropertyColorField(
                label: "", // No label
                value: shadowColor,
                onChanged: (val) => _updateValue('shadowColor', val),
                compact:
                    true, // We might need to add this property to PropertyColorField
                width: 30, // Square shape
              ),
            ),
          ],
        ),

        if (hasShadow) ...[
          const SizedBox(height: 8),
          // X and Y Row
          Row(
            children: [
              Expanded(
                child: _CompactNumberField(
                  label: "x",
                  value: shadowX,
                  onChanged: (val) => _updateValue('shadowX', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactNumberField(
                  label: "y",
                  value: shadowY,
                  onChanged: (val) => _updateValue('shadowY', val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Blur (r) and Spread (s) Row
          Row(
            children: [
              Expanded(
                child: _CompactNumberField(
                  label: "blur", // "r" in legacy
                  value: shadowBlur,
                  onChanged: (val) => _updateValue('shadowBlur', val),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactNumberField(
                  label: "spread", // "s" in legacy
                  value: shadowSpread,
                  onChanged: (val) => _updateValue('shadowSpread', val),
                ),
              ),
            ],
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

class _CompactNumberField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _CompactNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_CompactNumberField> createState() => _CompactNumberFieldState();
}

class _CompactNumberFieldState extends State<_CompactNumberField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringDisplay());
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_CompactNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.toStringDisplay() != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.value.toStringDisplay();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Submit on blur
      final val = double.tryParse(_controller.text);
      if (val != null) {
        widget.onChanged(val);
      } else {
        _controller.text = widget.value.toStringDisplay(); // Revert
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "${widget.label}: ",
          style: TextStyle(fontSize: 12, color: Pallet.font2),
        ),
        Expanded(
          child: SizedBox(
            height: 24,
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: InputDecoration(
                filled: true,
                fillColor: Pallet.inside2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
              onFieldSubmitted: (val) {
                final doubleVal = double.tryParse(val);
                if (doubleVal != null) widget.onChanged(doubleVal);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

extension on double {
  String toStringDisplay() {
    if (this % 1 == 0) return toInt().toString();
    return toString();
  }
}
