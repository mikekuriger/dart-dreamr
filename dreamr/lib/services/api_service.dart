import 'dart:convert';
import '../models/dream.dart';
import 'dio_client.dart';

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
  static Future<String> submitDream(String text) async {
    final response = await DioClient.dio.post('/api/chat',
      data: jsonEncode({'message': text}),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return data['analysis'] ?? 'No analysis returned.';
    } else {
      throw Exception('Dream submission failed: ${response.statusMessage}');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final res = await DioClient.dio.get('/api/dreams');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}


