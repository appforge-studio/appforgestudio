import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../services/arri_client.rpc.dart';
import '../utilities/pallet.dart';
import '../components/component_factory.dart';
import '../components/component_properties_factory.dart';

class AgenticEditsPanel extends StatefulWidget {
  const AgenticEditsPanel({super.key});

  @override
  State<AgenticEditsPanel> createState() => _AgenticEditsPanelState();
}

class _AgenticEditsPanelState extends State<AgenticEditsPanel> {
  final TextEditingController _promptController = TextEditingController();
  final RxBool _isLoading = false.obs;
  final RxBool _isIterateMode = false.obs;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canvasController = Get.find<CanvasController>();
    final hasSession = canvasController.currentSessionId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with mode toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  'AI Assistant',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (hasSession)
                Obx(() => InkWell(
                  onTap: () => _isIterateMode.value = !_isIterateMode.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isIterateMode.value
                          ? Colors.blue.shade900
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _isIterateMode.value
                            ? Colors.blue.shade700
                            : Pallet.divider,
                      ),
                    ),
                    child: Text(
                      'Iterate',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isIterateMode.value
                            ? Colors.white
                            : Pallet.font2,
                      ),
                    ),
                  ),
                )),
            ],
          ),
          const SizedBox(height: 10),

          // Text input area
          Expanded(
            child: TextField(
              controller: _promptController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: hasSession
                    ? (_isIterateMode.value
                        ? 'What would you like to change or fix?'
                        : 'Describe what you want to add or modify...')
                    : 'Describe the screen you want to generate...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: Pallet.inside2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Send button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading.value || _promptController.text.trim().isEmpty
                  ? null
                  : () => _handleGenerate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSession && _isIterateMode.value
                    ? Colors.blue.shade900
                    : Colors.purple.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasSession && _isIterateMode.value
                              ? Icons.edit
                              : Icons.auto_awesome,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoading.value
                              ? (hasSession && _isIterateMode.value
                                  ? 'Updating...'
                                  : 'Generating...')
                              : (hasSession && _isIterateMode.value
                                  ? 'Iterate'
                                  : 'Generate'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _handleGenerate() async {
    if (_promptController.text.trim().isEmpty) return;

    _isLoading.value = true;
    final prompt = _promptController.text.trim();
    final isIterate = Get.find<CanvasController>().currentSessionId.isNotEmpty &&
        _isIterateMode.value;

    try {
      await _generateDesign(prompt, isIterate: isIterate);
      _promptController.clear();
    } catch (e) {
      // Error handling is done in _generateDesign
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _generateDesign(
    String initialPrompt, {
    bool isIterate = false,
  }) async {
    final client = Get.find<ArriClient>();
    final canvasController = Get.find<CanvasController>();

    // Management of Session ID
    if (!isIterate) {
      canvasController.startNewSession();
    }
    final String sessionId = canvasController.currentSessionId;

    String currentPrompt = initialPrompt;
    int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        dynamic result;
        if (isIterate) {
          result = await client.ai.iterate_design(
            AiIterateDesignParams(
              prompt: currentPrompt,
              sessionId: sessionId,
            ),
          );
        } else {
          result = await client.ai.generate_design(
            GenerateDesignParams(prompt: currentPrompt, sessionId: sessionId),
          );
        }

        if (result.success && result.data != null) {
          Map<String, dynamic> designJson;
          if (result.data is Map<String, dynamic>) {
            designJson = result.data as Map<String, dynamic>;
          } else {
            try {
              designJson = Map<String, dynamic>.from(result.data);
            } catch (e) {
              Get.snackbar(
                'Error',
                'Invalid data format from AI',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }
          }

          // VALIDATE JSON ON FRONTEND
          final validationErrors = _validateDesignJson(designJson);

          if (validationErrors.isEmpty) {
            // Success!
            canvasController.fromJson(designJson, sessionId: sessionId);
            Get.snackbar(
              'Success',
              'Design generated successfully!',
              backgroundColor: Colors.green.withOpacity(0.9),
              colorText: Colors.white,
            );
            return; // Exit loop
          } else {
            // Validation failed, retry with errors
            debugPrint(
              '⚠️ Validation failed (Attempt $attempt/$maxRetries). Errors: $validationErrors',
            );
            if (attempt < maxRetries) {
              currentPrompt =
                  "The previous design had the following errors. Please fix them and return the corrected JSON:\n\n${validationErrors.join('\n')}\n\nOriginal Request: $initialPrompt";
            } else {
              Get.snackbar(
                'Error',
                'Generated design had errors after retries: ${validationErrors.first}',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );
            }
          }
        } else {
          Get.snackbar(
            'Error',
            result.message ?? 'Failed to generate design',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Connection failed: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }
  }

  List<String> _validateDesignJson(Map<String, dynamic> json) {
    final errors = <String>[];
    if (!json.containsKey('components')) {
      errors.add("Missing top-level 'components' array.");
      return errors;
    }

    final components = json['components'];
    if (components is! List) {
      errors.add("'components' must be a list.");
      return errors;
    }

    for (int i = 0; i < components.length; i++) {
      final comp = components[i];
      if (comp is! Map) {
        errors.add("Component at index $i is not an object.");
        continue;
      }

      final typeStr = comp['type'];
      if (typeStr == null) {
        errors.add("Component at index $i missing 'type'.");
        continue;
      }

      // Check if type exists
      ComponentType? type;
      try {
        type = ComponentType.values.firstWhere(
          (e) => e.name == typeStr,
        );
      } catch (_) {
        errors.add("Unknown component type '$typeStr' at index $i.");
        continue;
      }

      // Validate properties
      final properties = comp['properties'];
      if (properties is Map) {
        final validators = ComponentPropertiesFactory.getValidators(type);
        properties.forEach((key, value) {
          if (validators.containsKey(key)) {
            final error = validators[key]!(value);
            if (error != null) {
              errors.add("Component ${i} ($typeStr): $error");
            }
          }
        });
      }
    }
    return errors;
  }
}

