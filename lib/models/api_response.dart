import 'package:flutter/foundation.dart';

class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    T? data;
    try {
      if (json['data'] != null) {
        data = fromJson(json['data']);
      }
    } catch (e) {
      debugPrint('解析响应数据失败: $e');
    }

    return ApiResponse(
      code: json['code'] ?? 400,
      message: json['message'] ?? '请求失败',
      data: data,
    );
  }

  bool get isSuccess => code == 200;
} 