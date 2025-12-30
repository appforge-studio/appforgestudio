import 'package:flutter/material.dart';

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
    // Only update the text if the widget value changed AND we don't have focus
    // This allows external updates (like resize) to show up, 
    // but prevents fighting with the user while they type
    if (widget.value != _controller.text && !_focusNode.hasFocus) {
      // For numbers, we might want to check if they are effectively equal to avoid jumping
      // e.g. "10" vs "10.0"
      // But for now, direct string comparison is safer for exact sync
      _controller.text = widget.value;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // optionally re-sync on blur if needed
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: 'Enter ${widget.label.toLowerCase()}',
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
