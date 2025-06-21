import 'dart:convert';
import 'package:dreamr/models/dream.dart';
import 'dio_client.dart';
import 'package:dreamr/constants.dart';

class ApiService {
  // Login using email + password
  static Future<void> login(String email, String password) async {
    final response = await DioClient.dio.post('/api/login',
      data: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusMessage}');
    }
  }

  // Fetch dream journal (hidden = false)
  static Future<List<Dream>> fetchDreams() async {
    final response = await DioClient.dio.get('/api/dreams');

    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => Dream.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch dreams: ${response.statusMessage}');
    }
  }

  // Submit a dream to the AI
  static Future<Map<String, dynamic>> submitDream(String text) async {
    final response = await DioClient.dio.post(
      '/api/chat',
      data: jsonEncode({'message': text}),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return {
        'analysis': data['analysis'] ?? '',
        'tone': data['tone'] ?? '',
        'dream_id': data['dream_id']?.toString() ?? '',
      };
    } else {
      throw Exception('Dream submission failed: ${response.statusMessage}');
    }
  }

  // Generate Image
  static Future<String> generateDreamImage(int dreamId) async {
    final response = await DioClient.dio.post(
      '/api/image_generate',
      data: {"dream_id": dreamId},
    );

    final imagePath = response.data['image'] ?? '';
    // final baseUrl = AppConfig.baseUrl;

    return imagePath.startsWith('http')
        ? imagePath
        : '${AppConfig.baseUrl}$imagePath';
  }

  static Future<bool> isLoggedIn() async {
    try {
      final res = await DioClient.dio.get('/api/dreams');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // used to fetch user's name from back end
  static Future<Map<String, dynamic>> checkAuth() async {
    final response = await DioClient.dio.get('/api/check_auth');
    return response.data;
  }

}


