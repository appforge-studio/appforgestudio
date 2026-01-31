import 'package:flutter/material.dart';
import '../models/types/corner.dart';
import '../utilities/pallet.dart';

class PropertyCornerField extends StatelessWidget {
  final String label;
  final XDCorner value;
  final ValueChanged<XDCorner> onChanged;
  final List<String>? labels;
  final bool showLabel;

  const PropertyCornerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.labels,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabels = labels ?? ["tl", "tr", "br", "bl"];

    return Column(
      children: [
        Row(
          children: [
            if (showLabel)
              Text(label, style: TextStyle(color: Pallet.font1, fontSize: 13)),
            if (showLabel) const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Pallet.inside2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CornerButton(
                    type: CornerType.all,
                    active: value.type == CornerType.all,
                    onTap: () {
                      onChanged(
                        XDCorner(values: value.values, type: CornerType.all),
                      );
                    },
                  ),
                  Container(width: 1, height: 15, color: Pallet.divider),
                  _CornerButton(
                    type: CornerType.corner,
                    active: value.type == CornerType.corner,
                    onTap: () {
                      onChanged(
                        XDCorner(values: value.values, type: CornerType.corner),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (value.type == CornerType.all)
          Row(
            children: [
              Text(
                "all:  ",
                style: TextStyle(fontSize: 13, color: Pallet.font1),
              ),
              SizedBox(
                width: 50,
                child: _MiniTextField(
                  value: value.values[0].toString(),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(XDCorner.all(d));
                  },
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              _buildCornerInput(effectiveLabels[0], 0),
              const SizedBox(width: 10),
              _buildCornerInput(effectiveLabels[1], 1),
              const SizedBox(width: 10),
              _buildCornerInput(effectiveLabels[2], 2),
              const SizedBox(width: 10),
              _buildCornerInput(effectiveLabels[3], 3),
            ],
          ),
      ],
    );
  }

  Widget _buildCornerInput(String label, int index) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label:  ",
            style: TextStyle(fontSize: 13, color: Pallet.font1),
          ),
          Expanded(
            child: _MiniTextField(
              value: value.values[index].toString(),
              onChanged: (val) {
                final d = double.tryParse(val) ?? 0.0;
                final newValues = List<double>.from(value.values);
                newValues[index] = d;
                onChanged(XDCorner(values: newValues, type: CornerType.corner));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerButton extends StatelessWidget {
  final CornerType type;
  final bool active;
  final VoidCallback onTap;

  const _CornerButton({
    required this.type,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        padding: const EdgeInsets.all(6),
        child: CustomPaint(
          painter: _CornerIconPainter(type: type, active: active),
        ),
      ),
    );
  }
}

class _CornerIconPainter extends CustomPainter {
  final CornerType type;
  final bool active;

  _CornerIconPainter({required this.type, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? Pallet.inside3 : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (type == CornerType.all) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(3),
        ),
        paint,
      );
    } else {
      final w = size.width;
      final h = size.height;
      // Draw 4 separate corners
      // Top Left
      canvas.drawArc(Rect.fromLTWH(0, 0, 8, 8), 3.14, 1.57, false, paint);
      // Top Right
      canvas.drawArc(Rect.fromLTWH(w - 8, 0, 8, 8), -1.57, 1.57, false, paint);
      // Bottom Right
      canvas.drawArc(Rect.fromLTWH(w - 8, h - 8, 8, 8), 0, 1.57, false, paint);
      // Bottom Left
      canvas.drawArc(Rect.fromLTWH(0, h - 8, 8, 8), 1.57, 1.57, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MiniTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _MiniTextField({required this.value, required this.onChanged});

  @override
  State<_MiniTextField> createState() => _MiniTextFieldState();
}

class _MiniTextFieldState extends State<_MiniTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_MiniTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white, fontSize: 11),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          filled: true,
          fillColor: Pallet.inside2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(3),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: widget.onChanged,
        keyboardType: TextInputType.number,
      ),
    );
  }
}
