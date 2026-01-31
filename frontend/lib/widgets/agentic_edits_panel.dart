import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/canvas_controller.dart';
import '../services/arri_client.rpc.dart';
import '../utilities/pallet.dart';
import '../components/component_factory.dart';
import '../components/component_properties_factory.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utilities/api_key_helper.dart';

class AgenticEditsPanel extends StatefulWidget {
  const AgenticEditsPanel({super.key});

  @override
  State<AgenticEditsPanel> createState() => _AgenticEditsPanelState();
}

class _AgenticEditsPanelState extends State<AgenticEditsPanel> {
  final TextEditingController _promptController = TextEditingController();
  final RxBool _isLoading = false.obs;
  final RxBool _isIterateMode = false.obs;

  final RxString _promptText = ''.obs;

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      _promptText.value = _promptController.text;
    });
  }

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
                Obx(
                  () => InkWell(
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
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Text input area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
                const SizedBox(width: 8),
                Obx(() {
                  final canSend =
                      !_isLoading.value && _promptText.value.trim().isNotEmpty;
                  return _isLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: canSend ? () => _handleGenerate() : null,
                          icon: Icon(
                            hasSession && _isIterateMode.value
                                ? Icons.send
                                : Icons.auto_awesome,
                            color: canSend ? Colors.blue : Colors.grey,
                            size: 20,
                          ),
                        );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerate() async {
    if (_promptController.text.trim().isEmpty) return;

    _isLoading.value = true;

    // Check for API Key first
    final apiKey = await ApiKeyHelper.checkApiKey(context);
    if (apiKey == null) {
      _isLoading.value = false;
      return; // User cancelled or no key provided
    }

    final prompt = _promptController.text.trim();
    final isIterate =
        Get.find<CanvasController>().currentSessionId.isNotEmpty &&
        _isIterateMode.value;

    try {
      await _generateDesign(prompt, isIterate: isIterate, apiKey: apiKey);
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
    required String apiKey,
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
              apiKey: apiKey,
            ),
          );
        } else {
          result = await client.ai.generate_design(
            GenerateDesignParams(
              prompt: currentPrompt,
              sessionId: sessionId,
              apiKey: apiKey,
            ),
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

      // CASTING: Handle casting for string also if not string make it string
      final compProperties = comp['properties'];
      if (compProperties is Map) {
        final stringProps = [
          'content',
          'fontFamily',
          'icon',
          'text',
          'id',
          'imagePrompt',
        ];
        for (var prop in stringProps) {
          if (compProperties.containsKey(prop) &&
              compProperties[prop] != null &&
              compProperties[prop] is! String) {
            debugPrint(
              '🪄 Frontend casting $prop to string: ${compProperties[prop]}',
            );
            compProperties[prop] = compProperties[prop].toString();
          }
        }
      }

      // Check if type exists
      ComponentType? type;
      try {
        type = ComponentType.values.firstWhere((e) => e.name == typeStr);
      } catch (_) {
        errors.add("Unknown component type '$typeStr' at index $i.");
        continue;
      }

      // Validate properties
      final properties = comp['properties'];
      if (properties is Map) {
        // FONT VALIDATION
        if (properties.containsKey('fontFamily')) {
          String? fontFamily = properties['fontFamily'];
          if (fontFamily != null && fontFamily.isNotEmpty) {
            final validFonts = GoogleFonts.asMap().keys.toList();
            // Check exact match (case insensitive)
            final exactMatch = validFonts.firstWhereOrNull(
              (f) => f.toLowerCase() == fontFamily!.toLowerCase(),
            );

            if (exactMatch != null) {
              // Fix case if needed
              if (exactMatch != fontFamily) {
                debugPrint(
                  '🪄 Fixing font case: "$fontFamily" -> "$exactMatch"',
                );
                properties['fontFamily'] = exactMatch;
              }
            } else {
              // Find closest match
              debugPrint(
                '🔍 Font "$fontFamily" not found. Searching for closest match...',
              );
              final closest = _getClosestFont(fontFamily, validFonts);
              if (closest != null) {
                debugPrint(
                  '🪄 Replaced invalid font "$fontFamily" with "$closest"',
                );
                properties['fontFamily'] = closest;
              } else {
                // Fallback to Roboto if no close match found (unlikely)
                debugPrint(
                  '⚠️ No close font match found for "$fontFamily". Defaulting to Roboto.',
                );
                properties['fontFamily'] = 'Roboto';
              }
            }
          }
        }

        final validators = ComponentPropertiesFactory.getValidators(type);
        properties.forEach((key, value) {
          if (validators.containsKey(key)) {
            final error = validators[key]!(value);
            if (error != null) {
              final errorMsg = "Component $i ($typeStr): $error";
              errors.add(errorMsg);
              debugPrint('❌ Validation Error: $errorMsg');
              debugPrint('📦 Faulty Component: $comp');
            }
          }
        });
      }
    }
    return errors;
  }

  String? _getClosestFont(String target, List<String> candidates) {
    if (candidates.isEmpty) return null;

    String? closest;
    int minDistance = 999999;

    final targetLower = target.toLowerCase();

    for (final candidate in candidates) {
      final dist = _levenshtein(targetLower, candidate.toLowerCase());
      if (dist < minDistance) {
        minDistance = dist;
        closest = candidate;
      }
    }

    return closest;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((curr, next) => curr < next ? curr : next);
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}
