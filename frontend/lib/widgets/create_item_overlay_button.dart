import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'overlay_widgets.dart';
import '../utilities/pallet.dart'; // Ensure Pallet is imported if needed for specific colors not covered by widgets

// Placeholder for ColorPicker if it's not needed or complex to implement right away
// If the user insisted on color picker, we can add a simplified version or omit if not core for "Screens".
// The user code had `this.showColor = false` default, so we might skip it for Screens if not needed.
// However, I will keep the structure compatible.

class CreateItemOverlayButton extends StatefulWidget {
  const CreateItemOverlayButton({
    super.key,
    required this.onSave,
    this.showColor = false,
  });

  final Function(String, UuidValue?) onSave;
  final bool showColor;

  @override
  State<CreateItemOverlayButton> createState() =>
      _CreateItemOverlayButtonState();
}

class _CreateItemOverlayButtonState extends State<CreateItemOverlayButton> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _actionKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  UuidValue? _selectedColorId;
  bool _isOpen = false;

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  void _showOverlay() {
    final renderBox =
        _actionKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _hideOverlay,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 5,
                child: GestureDetector(
                  onTap: () {}, // Prevent tap from closing overlay
                  child: Material(
                    color: Colors.transparent,
                    child: GlassMorph(
                      width: 220,
                      borderRadius: 10,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name",
                            style: TextStyle(
                              color: Pallet.font1,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SmallTextBox(
                            controller: _controller,
                            hintText: "Enter name...",
                            onSubmitted: (value) {
                              if (_controller.text.trim().isNotEmpty) {
                                widget.onSave(
                                  _controller.text.trim(),
                                  _selectedColorId,
                                );
                                _controller.clear();
                                _hideOverlay();
                              }
                            },
                          ),
                          // Color picker section omitted for now as it wasn't strictly requested for "Screens"
                          // and requires more dependencies. Can add later if needed.
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SmallButton(
                                label: "Cancel",
                                onPress: _hideOverlay,
                              ),
                              const SizedBox(width: 8),
                              SmallButton(
                                label: "Save",
                                color: Pallet.inside3, // Using app color
                                onPress: () {
                                  if (_controller.text.trim().isNotEmpty) {
                                    widget.onSave(
                                      _controller.text.trim(),
                                      _selectedColorId,
                                    );
                                    _controller.clear();
                                    _hideOverlay();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AddButton(key: _actionKey, onPress: _toggle);
  }
}
