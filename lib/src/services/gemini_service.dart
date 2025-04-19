import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network_connector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeminiService {
  static const String _apiKeyStorageKey = 'gemini_api_key';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    // Use a more web-compatible configuration
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    webOptions: WebOptions(
      dbName: 'gifiti_secure',
      publicKey: 'gifiti_web_key',
    ),
  );
  static const String _modelName = 'gemini-2.0-flash';

  // Save API key securely
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  // Retrieve API key
  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }

  // Delete API key
  static Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  // Check if API key exists
  static Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  // Simple ping function for network test
  static Future<bool> ping() async {
    return await NetworkConnector.testConnection();
  }

  // Analyze image content using Gemini API
  static Future<Map<String, dynamic>?> analyzeImage(Uint8List imageBytes) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      // Construct request body
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Analyze this image and suggest 2-5 emoji characters that represent this image content. Also suggest a vibrant color (in hex format) that complements the image. Return a JSON object with two keys: "emojis" (string of emoji characters) and "color" (hex color code).'
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 100,
        }
      });

      // Make API request with fixed timeout
      final response = await NetworkConnector.post(
        Uri.parse('$_baseUrl/models/$_modelName:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          
          // Try to extract JSON format from the response text
          final jsonMatch = RegExp(r'\{[^}]*\}').firstMatch(content);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0);
            try {
              final jsonData = jsonDecode(jsonStr!);
              return {
                'emojis': jsonData['emojis'] ?? '',
                'color': _parseColorCode(jsonData['color'] ?? '')
              };
            } catch (e) {
              // If JSON parsing fails, try to extract manually
              return _manuallyExtractData(content);
            }
          } else {
            return _manuallyExtractData(content);
          }
        } catch (e) {
          return {'error': 'parse_error', 'message': '解析API响应时出错'};
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? '未知错误';
          
          if (errorMessage.contains('API key not valid')) {
            return {'error': 'invalid_api_key', 'message': 'API密钥无效'};
          } else if (response.statusCode == 404) {
            return {'error': 'model_not_found', 'message': '模型未找到'};
          } else {
            return {'error': 'api_error', 'message': '请求API时出错'};
          }
        } catch (e) {
          return {'error': 'unknown_error', 'message': '请求失败'};
        }
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('Failed host lookup')) {
        return {'error': 'connection_error', 'message': '无法连接到API服务器'};
      } else {
        return {'error': 'unknown_error', 'message': '未知错误'};
      }
    }
  }
  
  // Helper method to manually extract emoji and color from text response
  static Map<String, dynamic>? _manuallyExtractData(String content) {
    // Try to find emoji characters in the content
    final emojiPattern = RegExp(r'[\p{Emoji}]', unicode: true);
    final emojis = emojiPattern.allMatches(content).map((m) => m.group(0)).join();
    
    // Try to find hex color code in the content
    final colorPattern = RegExp(r'#[0-9A-Fa-f]{6}');
    final colorMatch = colorPattern.firstMatch(content);
    final colorCode = colorMatch?.group(0) ?? '';
    
    if (emojis.isNotEmpty || colorCode.isNotEmpty) {
      return {
        'emojis': emojis.isNotEmpty ? emojis : '',
        'color': _parseColorCode(colorCode),
      };
    }
    return null;
  }
  
  // Parse color code to ensure it's a valid hex color
    static Color _parseColorCode(String colorCode) {
    if (colorCode.startsWith('#') && (colorCode.length == 7 || colorCode.length == 9)) {
      try {
        return Color(int.parse('0xFF${colorCode.substring(1)}'));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }
} 