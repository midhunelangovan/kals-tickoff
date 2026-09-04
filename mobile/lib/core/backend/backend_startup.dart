import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';

class BackendStartup {
  static const MethodChannel _channel = MethodChannel('io.kals.tickoff/backend');

  static Future<bool> waitForReady({
    int maxAttempts = 20,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    // On non-Android platforms, assume backend is either managed externally (desktop dev)
    if (!Platform.isAndroid) {
      return true;
    }

    // Attempt to ping native MethodChannel first
    try {
      final isReady = await _channel.invokeMethod<bool>('isReady');
      if (isReady == true) {
        if (await _checkHttpHealth()) {
          return true;
        }
      } else {
        await _channel.invokeMethod('startBackend');
      }
    } catch (_) {
      // MethodChannel fallback to HTTP poll
    }

    // Poll HTTP health endpoint
    for (int i = 0; i < maxAttempts; i++) {
      if (await _checkHttpHealth()) {
        return true;
      }
      await Future.delayed(interval);
    }

    return false;
  }

  static Future<bool> _checkHttpHealth() async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
      final url = '${ApiConfig.apiBaseUrl}/internal/health';
      final response = await dio.get<dynamic>(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && (data['status'] == 'UP' || data.isNotEmpty)) {
          return true;
        }
        if (data is String && (data.contains('UP') || data.contains('{'))) {
          return true;
        }
        return true;
      }
    } catch (_) {
      // Still starting up
    }
    return false;
  }
}
