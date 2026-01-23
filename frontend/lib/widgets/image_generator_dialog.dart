import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../services/arri_client.rpc.dart';
import '../services/upload_service.dart';
import '../bindings/app_bindings.dart';
import '../utilities/pallet.dart';

class ImageGeneratorDialog extends StatefulWidget {
  const ImageGeneratorDialog({super.key});

  @override
  State<ImageGeneratorDialog> createState() => _ImageGeneratorDialogState();
}

class _ImageGeneratorDialogState extends State<ImageGeneratorDialog> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = "Please enter a prompt");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Get.find<ArriClient>();
      final result = await client.ai.generate_image(
        GenerateImageParams(prompt: prompt),
      );

      if (result.success && result.url != null) {
        final fullUrl = AppBindings.getAssetUrl(result.url!);
        Get.back(result: fullUrl);
      } else {
        setState(() => _error = result.message);
      }
    } catch (e) {
      setState(() => _error = "Generation failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.xFile != null) {
        final url = await UploadService.uploadFile(result.files.single.xFile!);
        if (url != null) {
          Get.back(result: url);
        } else {
          setState(() => _error = "Upload failed");
        }
      } else {
        // User canceled
      }
    } catch (e) {
      setState(() => _error = "Upload failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Pallet.inside1.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Generation',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter a prompt to generate an image...',
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
            ElevatedButton(
              onPressed: _isLoading ? null : _generateImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallet.inside3,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                  : const Text('Generate with AI'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white12)),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _uploadImage,
              icon: const Icon(Icons.upload_file, size: 20),
              label: const Text('Upload Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
