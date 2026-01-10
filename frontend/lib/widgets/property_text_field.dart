import 'package:flutter/material.dart';

import '../utilities/pallet.dart';

class PropertyTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  const PropertyTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<PropertyTextField> createState() => _PropertyTextFieldState();
}

class _PropertyTextFieldState extends State<PropertyTextField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(PropertyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && !_focusNode.hasFocus) {
      _controller.text = widget.value;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      if (widget.value != _controller.text) {
        _controller.text = widget.value;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80, // Fixed width for label similar to old UI
          child: Text(
            "${widget.label}:",
            style: TextStyle(fontSize: 13, color: Pallet.font1),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: SizedBox(
            height: 30, // Compact height
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ), // Reduced font size
              cursorColor: Colors.white70,
              cursorHeight: 12,
              decoration: InputDecoration(
                filled: true,
                fillColor: Pallet.inside2,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                hintText: 'Enter ${widget.label.toLowerCase()}',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
