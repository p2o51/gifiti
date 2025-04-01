import 'dart:async';
import 'package:http/http.dart' as http;

class NetworkConnector {
  // 尝试连接到一个可靠的服务器，用于测试网络连接
  static Future<bool> testConnection() async {
    try {
      // 尝试连接到可靠的CloudFlare服务
      final response = await http.get(
        Uri.parse('https://www.cloudflare.com/'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode < 400;
    } catch (e) {
      // 尝试Google服务
      try {
        final response = await http.get(
          Uri.parse('https://www.google.com/'),
        ).timeout(const Duration(seconds: 5));
        
        return response.statusCode < 400;
      } catch (e) {
        print('NetworkConnector: 所有连接测试失败: $e');
        return false;
      }
    }
  }

  // 发起HTTP GET请求
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    try {
      return await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      print('NetworkConnector: GET请求失败 $url: $e');
      rethrow;
    }
  }

  // 发起HTTP POST请求
  static Future<http.Response> post(Uri url, 
      {Map<String, String>? headers, dynamic body}) async {
    try {
      return await http.post(
        url, 
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      print('NetworkConnector: POST请求失败 $url: $e');
      rethrow;
    }
  }
} 