import 'package:dio/dio.dart';
import '../cache/cache_helper.dart';
import '../cache/cache_keys.dart';
import '../routing/named_routes.dart';
import '../utils/navigation_helper.dart';
import '../utils/logger.dart';
import 'end_points.dart';

/*
|--------------------------------------------------------------------------
| DioHelper
|--------------------------------------------------------------------------
|
| A centralized HTTP helper class built on top of Dio to handle all
| network requests in the application.
|
| Responsibilities:
|  • Initialize Dio with base configuration
|  • Handle GET, POST, DELETE requests
|  • Support file downloads with progress tracking
|  • Attach authorization tokens automatically
|  • Manage request headers (language, content type, auth)
|  • Support both JSON and FormData requests
|
|--------------------------------------------------------------------------
*/

class DioHelper {
  static late Dio dio;

  static init() {
    dio = Dio(
      BaseOptions(
        baseUrl: EndPoints.baseUrl,
        receiveDataWhenStatusError: true,
      ),
    );

    // Add 401 interceptor once here
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final path = error.requestOptions.path;

          final token = CacheHelper.getDataFromSharedPreference(
            key: CacheKeys.accessToken,
          );

          if (error.response?.statusCode == 401 &&
              path != EndPoints.epLogin &&
              token != null) {
            await CacheHelper.removeData(key: CacheKeys.accessToken);
            await CacheHelper.removeData(key: CacheKeys.refreshToken);

            pushAndRemoveUntil(NamedRoutes.signin);
          }

          handler.next(error);
        },
      ),
    );
  }

  static Future<Response> downloadMedia({
    required String url,
    required String path,
    Map<String, dynamic>? query,
    Function(int, int)? onReceiveProgress,
    String? token,
  }) async {
    dio.options.headers = {
      'Accept-Language': CacheHelper.getDataFromSharedPreference(
        key: CacheKeys.appLang,
      ),
    };
    dio.options.headers['Authorization'] =
        'Bearer ${token ?? CacheHelper.getDataFromSharedPreference(
              key: CacheKeys.accessToken,
            )}';

    return await dio.download(
      url,
      path,
      queryParameters: query,
      onReceiveProgress: onReceiveProgress,
    );
  }

  static Future<Response> deleteData({
    required String url,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    dio.options.headers = {
      'Accept': 'application/json',
      'Authorization':
          "Bearer ${token ?? CacheHelper.getDataFromSharedPreference(
                key: CacheKeys.accessToken,
              )}",
    };
    return await dio.delete(
      url,
      queryParameters: query,
    );
  }

  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    logger.i("$url");
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization':
          "Bearer ${token ?? CacheHelper.getDataFromSharedPreference(
                key: CacheKeys.accessToken,
              )}",
    };
    return await dio.get(url, queryParameters: query);
  }

  static Future<Response> postData({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    bool isForm = false,
    String? token,

    /// Pre-built FormData (e.g. with files). When provided, [body] and
    /// [isForm] are ignored and no Content-Type header is set so Dio can
    /// auto-inject the correct multipart boundary.
    FormData? formDataOverride,
  }) async {
    logger.i("$url");

    if (formDataOverride != null) {
      // For multipart uploads let Dio manage Content-Type (boundary header).
      dio.options.headers = {
        'Accept': 'application/json',
        'Authorization':
            "Bearer ${token ?? CacheHelper.getDataFromSharedPreference(
                  key: CacheKeys.accessToken,
                )}",
      };
      return await dio.post(url,
          queryParameters: query, data: formDataOverride);
    }

    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization':
          "Bearer ${token ?? CacheHelper.getDataFromSharedPreference(
                key: CacheKeys.accessToken,
              )}",
    };
    return await dio.post(
      url,
      queryParameters: query,
      data: body != null && isForm ? FormData.fromMap(body) : body,
    );
  }
}
