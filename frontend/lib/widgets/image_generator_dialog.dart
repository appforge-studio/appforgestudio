import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../services/upload_service.dart';
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
  double _steps = 4;
  String _aspectRatio = 'Square (1:1)';
  String? _previewImage; // Base64 encoded image string

  final Map<String, Size> _aspectRatios = {
    'Square (1:1)': const Size(1024, 1024),
    'Landscape (16:9)': const Size(1024, 576),
    'Portrait (9:16)': const Size(576, 1024),
  };

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = "Please enter a prompt");
      return;
    }

    final size = _aspectRatios[_aspectRatio]!;
    Get.back(
      result: {
        'action': 'generate',
        'prompt': prompt,
        'steps': _steps,
        'width': size.width,
        'height': size.height,
      },
    );
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
          Get.back(result: {'url': url});
        } else {
          setState(() => _error = "Upload failed");
        }
      } else {
        // User canceled
      }
    } catch (e) {
      setState(() => _error = "Upload failed: $e");
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
            // Preview Image Area
            if (_isLoading && _previewImage != null)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                  image: DecorationImage(
                    image: MemoryImage(
                      base64Decode(_previewImage!.split(',').last),
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              )
            else
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
              maxLines: 2,
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
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ratio',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _aspectRatios.keys.map((String key) {
                          final isSelected = _aspectRatio == key;
                          final ratio = key.contains('1:1')
                              ? 1.0
                              : (key.contains('16:9') ? 16 / 9 : 9 / 16);

                          return Expanded(
                            child: Container(
                              height: 60,
                              padding: EdgeInsets.only(
                                right: key == _aspectRatios.keys.last ? 0 : 4.0,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(() => _aspectRatio = key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Pallet.inside3.withOpacity(0.1)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Pallet.inside3
                                          : Colors.white10,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 16,
                                        width: 16 * (ratio > 1 ? 1.4 : 1.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? Pallet.inside3
                                                : Colors.white38,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: AspectRatio(
                                            aspectRatio: ratio,
                                            child: Container(
                                              margin: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Pallet.inside3
                                                          .withOpacity(0.5)
                                                    : Colors.white10,
                                                borderRadius:
                                                    BorderRadius.circular(0.5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        key.split('(').last.replaceAll(')', ''),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 9,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
