import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/arri_client.rpc.dart';
import '../utilities/pallet.dart';
import '../bindings/app_bindings.dart';
import 'mask_editor.dart';

class ImageEditingDialog extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;

  const ImageEditingDialog({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  State<ImageEditingDialog> createState() => _ImageEditingDialogState();
}

class _ImageEditingDialogState extends State<ImageEditingDialog> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  ui.Image? _maskImage;
  double _steps = 4.0;
  bool _generateNewImage = false;

  // Version Management
  final List<String> _history = [];
  int _currentIndex = -1;

  String? get _resultUrl => _currentIndex >= 0 ? _history[_currentIndex] : null;

  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() => _error = "Please enter a prompt");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Get.find<ArriClient>();
      String? url;

      // Use the currently selected image as the base for the next generation
      final String baseImageUrl = _resultUrl ?? widget.imageUrl;

      if (_generateNewImage) {
        // Text-to-Image Mode (workflow.json only)
        final response = await client.ai.generate_image(
          GenerateImageParams(
            prompt: _promptController.text.trim(),
            width: widget.width,
            height: widget.height,
            steps: _steps,
          ),
        );

        if (response.success) {
          url = response.url;
        } else {
          setState(() => _error = response.message);
        }
      } else if (_maskImage != null) {
        // Inpainting Mode
        final maskBytes = await _maskImage!.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final maskBase64 = base64Encode(maskBytes!.buffer.asUint8List());

        final response = await client.ai.inpaint_image(
          InpaintImageParams(
            prompt: _promptController.text.trim(),
            image: baseImageUrl,
            mask: maskBase64,
            width: widget.width,
            height: widget.height,
            steps: _steps,
          ),
        );

        if (response.success) {
          url = response.url;
        } else {
          setState(() => _error = response.message);
        }
      } else {
        // Edit Image Mode
        final response = await client.ai.edit_image(
          EditImageParams(
            prompt: _promptController.text.trim(),
            image: baseImageUrl,
            steps: _steps.toDouble(),
          ),
        );

        if (response.success) {
          url = response.data.toString();
        } else {
          setState(() => _error = response.message);
        }
      }

      if (url != null) {
        final absoluteUrl = AppBindings.getAssetUrl(url);
        setState(() {
          // If we were in the middle of history, clear forward history?
          // Standard behavior for undo/redo stacks.
          if (_currentIndex < _history.length - 1) {
            _history.removeRange(_currentIndex + 1, _history.length);
          }
          _history.add(absoluteUrl);
          _currentIndex = _history.length - 1;
        });
      }
    } catch (e) {
      setState(() => _error = "Failed to generate: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _undo() {
    if (_currentIndex >= 0) {
      setState(() => _currentIndex--);
    }
  }

  void _redo() {
    if (_currentIndex < _history.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _restore() {
    setState(() {
      _history.clear();
      _currentIndex = -1;
      _maskImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 800, // Increased height for history
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Pallet.inside1.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Image Editing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_history.isNotEmpty)
                      IconButton(
                        onPressed: _restore,
                        tooltip: "Restore Original",
                        icon: const Icon(Icons.restore, color: Colors.white70),
                      ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image Area (Mask Editor or Preview)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  MaskEditor(
                    key: ValueKey(
                      _currentIndex,
                    ), // Rebuild when version changes
                    imageUrl: _resultUrl ?? widget.imageUrl,
                    imageWidth: widget.width,
                    imageHeight: widget.height,
                    onMaskChanged: (img) => _maskImage = img,
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Version Management Bar
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _currentIndex > -1 ? _undo : null,
                      icon: const Icon(Icons.undo, color: Colors.white),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _history.length + 1,
                        itemBuilder: (context, index) {
                          final isOriginal = index == 0;
                          final historyIdx = index - 1;
                          final isSelected = historyIdx == _currentIndex;
                          final thumbUrl = isOriginal
                              ? widget.imageUrl
                              : _history[historyIdx];

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _currentIndex = historyIdx),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Pallet.inside3
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  thumbUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _currentIndex < _history.length - 1
                          ? _redo
                          : null,
                      icon: const Icon(Icons.redo, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Controls Area
            TextField(
              controller: _promptController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Describe changes (e.g. "make the car green")',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Generation Quality / Steps',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Generate New Image',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Transform.scale(
                          scale: 0.7,
                          child: Checkbox(
                            value: _generateNewImage,
                            activeColor: Pallet.inside3,
                            onChanged: (value) => setState(
                              () => _generateNewImage = value ?? false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Pallet.inside3,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          trackHeight: 2,
                        ),
                        child: Slider(
                          value: _steps,
                          min: 2,
                          max: 8,
                          divisions: 6,
                          label: "Steps: ${_steps.round()}",
                          onChanged: (value) => setState(() => _steps = value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallet.inside3,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Generate'),
                    ),
                  ],
                ),
              ],
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _currentIndex == -1 && _history.isEmpty
                      ? null
                      : () {
                          Get.back(result: _resultUrl);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Apply Selected Version"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
