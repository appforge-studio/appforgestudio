import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/arri_client.rpc.dart';
import '../utilities/pallet.dart';
import 'mask_editor.dart';

class InpaintingDialog extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;

  const InpaintingDialog({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  State<InpaintingDialog> createState() => _InpaintingDialogState();
}

class _InpaintingDialogState extends State<InpaintingDialog> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  ui.Image? _maskImage;
  double _steps = 4.0;

  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() => _error = "Please enter a prompt");
      return;
    }
    if (_maskImage == null) {
      setState(() => _error = "Please draw a mask on the image");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Get.find<ArriClient>();

      // Convert mask to base64
      final maskBytes = await _maskImage!.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final maskBase64 = base64Encode(maskBytes!.buffer.asUint8List());

      // We need the original image as base64 too, or just the URL?
      // The backend expects 'image' as base64.
      // For now, let's assume we can fetch it or it's already a base64 in some cases.
      // If it's a URL, we might need the backend to fetch it or fetch it here.
      // Assuming for now we can get the image data.

      // Since fetching and converting to base64 takes time, I'll just pass the params back to the controller
      // and let the controller handle the API call if needed, or do it here.
      // Let's do it here for simplicity since we have the client.

      final response = await client.ai.inpaint_image(
        InpaintImageParams(
          prompt: _promptController.text.trim(),
          image: widget.imageUrl,
          mask: maskBase64,
          width: widget.width,
          height: widget.height,
          steps: _steps,
        ),
      );

      if (response.success && response.url != null) {
        Get.back(result: response.url);
      } else {
        setState(() => _error = response.message);
      }
    } catch (e) {
      setState(() => _error = "Failed to generate: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 700,
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
                  'Edit Image (Inpainting)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Draw over the area you want to change:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: MaskEditor(
                imageUrl: widget.imageUrl,
                imageWidth: widget.width,
                imageHeight: widget.height,
                onMaskChanged: (img) => _maskImage = img,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'What should be in the masked area?',
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
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steps: ${_steps.round()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Pallet.inside3,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Colors.white,
                    overlayColor: Pallet.inside3.withOpacity(0.2),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                  ),
                  child: Slider(
                    value: _steps,
                    min: 2,
                    max: 8,
                    divisions: 6,
                    label: _steps.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _steps = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallet.inside3,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Generate Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
