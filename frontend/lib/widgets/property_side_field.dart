import 'package:flutter/material.dart';
import '../models/types/side.dart';
import '../utilities/pallet.dart';

class PropertySideField extends StatelessWidget {
  final String label;
  final XDSide value;
  final ValueChanged<XDSide> onChanged;

  final List<String>? labels;

  const PropertySideField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.labels,
    this.showLabel = true,
  });

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabels = labels ?? ["t", "r", "b", "l"];
    // Wait, the old code used "t", "b", "l", "r" order in UI row?
    // Code: t, b, l, r.
    // values indices: 0, 1, 2, 3.
    // XDSide: [top, right, bottom, left]. (0, 1, 2, 3)
    // So if UI is t(0), b(2), l(3), r(1).
    // I should check my previous implementation of PropertySideField to see order.

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
                  _SideButton(
                    type: SideType.all,
                    active: value.type == SideType.all,
                    onTap: () {
                      onChanged(
                        XDSide(values: value.values, type: SideType.all),
                      );
                    },
                  ),
                  Container(width: 1, height: 15, color: Pallet.divider),
                  _SideButton(
                    type: SideType.side,
                    active: value.type == SideType.side,
                    onTap: () {
                      onChanged(
                        XDSide(values: value.values, type: SideType.side),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (value.type == SideType.all)
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
                    onChanged(XDSide.all(d));
                  },
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              _buildSideInput(effectiveLabels[0], 0),
              const SizedBox(width: 10),
              _buildSideInput(
                effectiveLabels[2],
                2,
              ), // Index 2 is Bottom in XDSide? XDSide says [top, right, bottom, left].
              // If we assume UI was Top, Bottom, ...
              // Let's stick to indices: 0=Top, 1=Right, 2=Bottom, 3=Left.
              // So labels should be [T, R, B, L] to match indices?
              // The passed effectiveLabels should be in order of [0, 1, 2, 3] usually.
              // But here I'm hardcoding indices 0 and 2.
              // If I pass labels ["tl", "tr", "br", "bl"] (indices 0, 1, 2, 3).
              // I want UI Row 1: TL (0), TR (1). Row 2: BL (3), BR (2)?
              // Actually, standard usually is TL, TR, BR, BL (clockwise).
              // Let's just use indices 0, 1, 2, 3 from the labels array, but arrange them in UI as we wish.
              // Padding UI was T(0), B(2), L(3), R(1).
              // If I want Border Radius to be TL(0), TR(1), BL(3), BR(2).
              // I should probably make the layout configurable too?
              const SizedBox(width: 10),
              _buildSideInput(effectiveLabels[3], 3),
              const SizedBox(width: 10),
              _buildSideInput(effectiveLabels[1], 1),
            ],
          ),
      ],
    );
  }

  Widget _buildSideInput(String label, int index) {
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
                onChanged(XDSide(values: newValues, type: SideType.side));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final SideType type;
  final bool active;
  final VoidCallback onTap;

  const _SideButton({
    required this.type,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Implement drawing of the icon (square vs corners)
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24, // increased touch area slightly
        height: 24,
        padding: EdgeInsets.all(6),
        child: CustomPaint(
          painter: _SideIconPainter(type: type, active: active),
        ),
      ),
    );
  }
}

class _SideIconPainter extends CustomPainter {
  final SideType type;
  final bool active;

  _SideIconPainter({required this.type, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = active ? Pallet.inside3 : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (type == SideType.all) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else {
      // Draw corners/sides
      final w = size.width;
      final h = size.height;
      // Top
      canvas.drawLine(Offset(2, 0), Offset(w - 2, 0), paint);
      // Left
      canvas.drawLine(Offset(0, 2), Offset(0, h - 2), paint);
      // others... maybe just dotted or separated?
      // frontend_old2 used a specific look.
      // Let's just draw a "frame" open at corners or something distinct.
      // actually, let's just draw lines.
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
            borderRadius: BorderRadius.circular(3), // slightly sharper
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: widget.onChanged,
        keyboardType: TextInputType.number,
      ),
    );
  }
}
