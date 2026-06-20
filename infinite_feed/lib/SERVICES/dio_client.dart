
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';

class Dioclient {
  static late final Dio dio;

  static void init() {
    BaseOptions options = BaseOptions(
      baseUrl: "http://localhost:5000/",
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );

    dio = Dio(options);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('➡️ ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ ${response.statusCode} ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (e, handler) {
          debugPrint(
            '❌ ${e.response?.statusCode} ${e.requestOptions.uri}',
          );
          handler.next(e);
        },
      ),
    );
  }
}