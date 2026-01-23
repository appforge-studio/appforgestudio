import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:cross_file/cross_file.dart';
import '../bindings/app_bindings.dart';

class UploadService {
  static Future<String?> uploadFile(XFile file) async {
    try {
      final uri = Uri.parse('${AppBindings.baseUrl}/media/upload');
      final request = http.MultipartRequest('POST', uri);

      // Determine content type (mime type)
      // Basic fallback if lookup fails
      final mimeType = file.mimeType ?? 'application/octet-stream';
      final mediaType = MediaType.parse(mimeType);

      // Create multipart file from XFile
      // For web, we might need readAsBytes, for desktop default path works
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: file.name,
            contentType: mediaType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: mediaType,
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Upload success: ${data['url']}');

          // Return the full URL using AppBindings helper
          return AppBindings.getAssetUrl(data['url'] as String);
        } else {
          debugPrint('❌ Upload server error: ${data['message']}');
          return null;
        }
      } else {
        debugPrint(
          '❌ Upload http error: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Upload exception: $e');
      return null;
    }
  }
}
