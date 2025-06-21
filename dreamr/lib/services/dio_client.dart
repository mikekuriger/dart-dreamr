import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dreamr/constants.dart';

class DioClient {
  static late final Dio dio;

  static Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${appDocDir.path}/.cookies/'),
    );

    dio = Dio(BaseOptions(
      baseUrl: '${AppConfig.baseUrl}',
      headers: {
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    dio.interceptors.add(CookieManager(cookieJar));
  }
}

