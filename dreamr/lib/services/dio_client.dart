// services/dio_client.dart
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dreamr/constants.dart';

class DioClient {
  static late final Dio dio;
  static PersistCookieJar? _cookieJar;

  static Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();

    // store the jar so we can wipe it on logout
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${appDocDir.path}/.cookies/'),
    );

    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ));

    dio.interceptors.add(CookieManager(_cookieJar!));
  }

  // Added so logout can actually clear the session
  static Future<void> clearCookies() async {
    await _cookieJar?.deleteAll();
  }

  // (optional) if you ever set an auth header, clear it too
  static void removeAuthHeader() {
    dio.options.headers.remove('Authorization');
  }
}
