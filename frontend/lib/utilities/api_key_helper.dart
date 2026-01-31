import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../utilities/pallet.dart';

class ApiKeyHelper {
  static const String _storageKey = 'gemini_api_key';

  static Future<String?> checkApiKey(BuildContext context) async {
    final box = GetStorage();
    String? storedKey = box.read(_storageKey);

    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }

    return await _showApiKeyDialog(context);
  }

  static Future<String?> _showApiKeyDialog(BuildContext context) async {
    final TextEditingController keyController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Pallet.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Pallet.divider, width: 1),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Gemini API Key',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'To use AI features, you need to provide your own Google Gemini API key. This key is stored locally on your device.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: keyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Paste your API Key here',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Pallet.inside2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      final box = GetStorage();
                      box.write(_storageKey, value.trim());
                      Navigator.of(context).pop(value.trim());
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (keyController.text.trim().isNotEmpty) {
                          final box = GetStorage();
                          box.write(_storageKey, keyController.text.trim());
                          Navigator.of(context).pop(keyController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Save & Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
