import 'dart:convert';
import 'package:dreamr/models/dream.dart';
import 'dio_client.dart';
import 'package:dio/dio.dart';
import 'package:dreamr/constants.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiService {
  // Register using email + password
  static Future<String> register(String firstName, String email, String password) async {
      String timezone = await FlutterTimezone.getLocalTimezone();

      final response = await DioClient.dio.post(
        '/api/register',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'timezone': timezone,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (_) => true, // <---- this is KEY
        ),
      );

      // debugPrint("📦 Response status: ${response.statusCode}");
      // debugPrint("📦 Response data: ${response.data.runtimeType} - ${response.data}");

      if (response.statusCode == 200) {
        return "✅ Check your email to confirm your Dreamr✨ account.";
      } else {
        if (response.data is Map && response.data['error'] != null) {
          return "❌ ${response.data['error']}";
        } else if (response.data is String) {
          return "❌ ${response.data}";
        } else {
          return "❌ Registration failed.";
        }
      }
  }



  // Login using email + password
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await DioClient.dio.post(
      '/api/login',
      data: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusMessage}');
    }

    final secureStorage = FlutterSecureStorage();

    await secureStorage.write(key: 'email', value: email);
    await secureStorage.write(key: 'password', value: password);
    
    return response.data['user'];
  }

  // static Future<void> login(String email, String password) async {
  //   final response = await DioClient.dio.post('/api/login',
  //     data: jsonEncode({
  //       'email': email,
  //       'password': password,
  //     }),
  //   );

  //   if (response.statusCode != 200) {
  //     throw Exception('Login failed: ${response.statusMessage}');
  //   }
  // }

  // Google auth
  static Future<void> googleLogin(String idToken) async {
    debugPrint("🔥 Attempting Google login with token: $idToken");

    final response = await DioClient.dio.post(
      '/api/google_login',
      data: {'id_token': idToken},
    );

    if (response.statusCode != 200) {
      throw Exception("Google login failed");
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
  // static Future<Map<String, dynamic>> submitDream(String text, {int? draftId}) async {
  static Future<Map<String, dynamic>> submitDream(String text) async {
    // final data = {
    //   'message': text,
    //   if (draftId != null) 'id': draftId,
    // };

    final response = await DioClient.dio.post(
      '/api/chat',
      // data: jsonEncode(data),
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

  // Save dream for later
  // static Future<Map<String, dynamic>> saveDraft(String text) async {
  //   final response = await DioClient.dio.post(
  //     '/api/draft',
  //     data: jsonEncode({'message': text}),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = response.data;
  //     return {
  //       'dream_id': data['dream_id']?.toString() ?? '',
  //     };
  //   } else {
  //     throw Exception('Draft submission failed: ${response.statusMessage}');
  //   }
  // }

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


