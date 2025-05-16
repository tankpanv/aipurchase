import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../utils/storage.dart';
import '../models/api_response.dart';
import 'package:dio/io.dart';

class ApiService extends GetxService {
  late final Dio _dio;
  final String baseUrl = kDebugMode 
    ? 'https://sqdftauejboz.sealoshzh.site' 
    : 'https://sqdftauejboz.sealoshzh.site';  // 生产环境使用HTTPS

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(minutes: 10),
        headers: {'Accept': 'application/json'},
      ),
    );

    // 添加HTTPS证书验证配置
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) {
        // 允许aipurchase_server.huanfangsk.com的自签名证书，无论是调试还是生产环境
        if (host == 'aipurchase_server.huanfangsk.com') {
          return true;
        }
        return false;
      };
      return client;
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          developer.log('API Request: ${options.method} ${options.path}');
          developer.log('Request Headers: ${options.headers}');
          if (options.data != null) {
            developer.log('Request Data: ${options.data}');
          }
          
          final token = await Storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log('API Response: ${response.statusCode}');
          developer.log('Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          developer.log('API Error: ${error.message}');
          developer.log('Error Response: ${error.response?.data}');
          
          if (error.response?.statusCode == 401) {
            Storage.clearToken();
            Get.offAllNamed('/login');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    try {
      developer.log('发送POST请求: $path');
      developer.log('请求数据: $data');
      final response = await _dio.post<T>(path, data: data);
      developer.log('POST响应: ${response.data}');
      return response;
    } on DioException catch (e) {
      developer.log('POST请求失败(DioException): ${e.type} ${e.message}');
      developer.log('错误响应数据: ${e.response?.data}');
      developer.log('错误响应状态码: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        Get.offAllNamed('/login');
      }
      rethrow;
    } catch (e) {
      developer.log('POST请求失败(其他异常): $e');
      rethrow;
    }
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    try {
      return await _dio.put<T>(path, data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) async {
    try {
      return await _dio.delete<T>(path, data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      debugPrint('获取Token异常: $e');
      return null;
    }
  }
  
  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      debugPrint('Token已清除');
    } catch (e) {
      debugPrint('清除Token异常: $e');
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String userName,
    required String password,
  }) async {
    try {
      debugPrint('登录请求参数: userName=$userName');
      
      final response = await _dio.post('/api/app/login', data: {
        'user_name': userName,
        'password': password,
      });
      
      debugPrint('登录响应: ${response.statusCode} ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        await Storage.saveToken(data['access_token']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('user_name', data['user_name']);
      }
      
      return ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      debugPrint('登录异常: ${e.type} ${e.message}');
      
      var errorMessage = '网络请求失败';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.response?.statusMessage != null) {
        errorMessage = e.response?.statusMessage ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '连接超时，请检查网络';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = '未知网络错误: ${e.message}';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '连接服务器失败，请检查网络或服务器地址';
      }
      
      debugPrint('登录错误详情: ${e.response?.statusCode} ${e.response?.data}');
      debugPrint('错误信息: $errorMessage');
      
      return ApiResponse(code: 500, message: errorMessage);
    } catch (e) {
      debugPrint('登录未知异常: $e');
      return ApiResponse(code: 500, message: '未知错误: $e');
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String userName,
    required String password,
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      debugPrint('注册请求参数: userName=$userName, name=$name, phone=$phone');
      
      final response = await _dio.post('/api/app/register', data: {
        'user_name': userName,
        'password': password,
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
      });
      
      debugPrint('注册响应: ${response.statusCode} ${response.data}');
      return ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      debugPrint('注册异常: ${e.type} ${e.message}');
      debugPrint('注册错误详情: ${e.response?.statusCode} ${e.response?.data}');
      return ApiResponse(
        code: e.response?.statusCode ?? 500,
        message: e.response?.data?['message'] ?? e.response?.statusMessage ?? '网络请求失败: ${e.message}',
      );
    } catch (e) {
      debugPrint('注册未知异常: $e');
      return ApiResponse(code: 500, message: '未知错误: $e');
    }
  }

  Future<ApiResponse<User>> getUserInfo() async {
    try {
      debugPrint('获取用户信息请求');
      
      final response = await _dio.get('/api/app/user/info');
      
      debugPrint('获取用户信息响应: ${response.statusCode} ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'];
        if (userData != null) {
          final user = User.fromJson(userData);
          return ApiResponse(
            code: response.data['code'] ?? 200,
            message: response.data['message'] ?? '获取成功',
            data: user,
          );
        }
      }
      
      return ApiResponse(
        code: response.data?['code'] ?? 400,
        message: response.data?['message'] ?? '获取用户信息失败',
      );
    } on DioException catch (e) {
      debugPrint('获取用户信息异常: ${e.type} ${e.message}');
      debugPrint('获取用户信息错误详情: ${e.response?.statusCode} ${e.response?.data}');
      return ApiResponse(
        code: e.response?.statusCode ?? 500,
        message: e.response?.data?['message'] ?? e.response?.statusMessage ?? '网络请求失败',
      );
    } catch (e) {
      debugPrint('获取用户信息未知异常: $e');
      return ApiResponse(code: 500, message: '未知错误: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateUserInfo({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      final response = await _dio.post('/api/app/user/update', data: {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
      });
      
      return ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return ApiResponse(
        code: e.response?.statusCode ?? 500,
        message: e.response?.statusMessage ?? '网络请求失败',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post('/api/app/user/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      
      return ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return ApiResponse(
        code: e.response?.statusCode ?? 500,
        message: e.response?.statusMessage ?? '网络请求失败',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    await Storage.removeToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    return ApiResponse(
      code: 200,
      message: '已成功退出登录',
      data: {'success': true},
    );
  }

  Future<Map<String, dynamic>> chatWithAI({
    required List<Map<String, String>> messages,
    required String agentId,
    double temperature = 0.7,
    int maxTokens = 800,
    String? agentName,
    String? agentPrompt,
  }) async {
    try {
      debugPrint('发送AI聊天请求');
      
      final token = await Storage.getToken();
      if (token == null) {
        return {
          'error': true,
          'message': '请先登录'
        };
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final requestData = {
          'model': 'dify-workflow',
          'messages': messages,
          'stream': false,
          'user_token': token,
          'user_id': userId.toString(),
          'provider': 'dify',
          'agent_id': agentId
      };
      
      // 添加智能体信息（如果有）
      if (agentName != null) {
        requestData['agent_name'] = agentName;
      }
      
      if (agentPrompt != null) {
        requestData['agent_prompt'] = agentPrompt;
      }

      debugPrint('AI请求数据: $requestData');
      
      final response = await _dio.post(
        '/chat/v1/chat/completions',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          sendTimeout: const Duration(seconds: 600),
          receiveTimeout: const Duration(seconds: 600),
        ),
      );
      
      debugPrint('AI响应: ${response.statusCode}');
      return response.data;
    } on DioException catch (e) {
      debugPrint('AI聊天异常: ${e.type} ${e.message}');
      return {
        'error': true,
        'message': e.response?.data?['message'] ?? '请求失败，请稍后再试'
      };
    } catch (e) {
      debugPrint('AI聊天未知异常: $e');
      return {
        'error': true,
        'message': '发生未知错误: $e'
      };
    }
  }

  Future<ProductsResponse> getProducts({
    int? merchantId,
    int? categoryId,
    String? keyword,
    String? productType,
    bool? isFeatured,
    int page = 1,
    int perPage = 10,
    String? sort,
    String? order,
  }) async {
    try {
      debugPrint('获取商品列表请求: page=$page, type=$productType');
      
      final Map<String, dynamic> queryParams = {
        'page': page,
        'per_page': perPage,
      };
      
      if (merchantId != null) queryParams['merchant_id'] = merchantId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (keyword != null) queryParams['keyword'] = keyword;
      if (productType != null) queryParams['product_type'] = productType;
      if (isFeatured != null) queryParams['is_featured'] = isFeatured;
      if (sort != null) queryParams['sort'] = sort;
      if (order != null) queryParams['order'] = order;
      
      final response = await _dio.get(
        '/api/app/products',
        queryParameters: queryParams,
      );
      
      debugPrint('获取商品列表响应: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return ProductsResponse.fromJson(response.data);
      }
      
      return ProductsResponse(
        code: response.statusCode ?? 400,
        message: '请求失败',
        products: [],
        total: 0,
        pages: 0,
        currentPage: page,
      );
    } on DioException catch (e) {
      debugPrint('获取商品列表异常: ${e.type} ${e.message}');
      debugPrint('获取商品列表错误详情: ${e.response?.statusCode} ${e.response?.data}');
      
      return ProductsResponse(
        code: e.response?.statusCode ?? 400,
        message: e.response?.data?['message'] ?? '网络请求失败',
        products: [],
        total: 0,
        pages: 0,
        currentPage: page,
      );
    } catch (e) {
      debugPrint('获取商品列表未知异常: $e');
      
      return ProductsResponse(
        code: 400,
        message: '发生未知错误: $e',
        products: [],
        total: 0,
        pages: 0,
        currentPage: page,
      );
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data['message'] != null) {
        return Exception(error.response?.data['message']);
      }
      return Exception(error.message);
    }
    return Exception('An unexpected error occurred');
  }
} 