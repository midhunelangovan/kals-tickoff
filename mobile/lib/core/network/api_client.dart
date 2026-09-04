import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        developer.log(
          '--> ${options.method} ${options.uri}',
          name: 'DioClient',
        );
        if (options.data != null) {
          developer.log('Body: ${options.data}', name: 'DioClient');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        developer.log(
          '<-- ${response.statusCode} ${response.requestOptions.uri}',
          name: 'DioClient',
        );
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        developer.log(
          '<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}: ${e.message}',
          name: 'DioClient',
          error: e,
        );
        return handler.next(e);
      },
    ),
  );

  return dio;
});
