import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
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
    String? bio,
    List<String>? tags,
    List<String>? interests,
  }) async {
    try {
      final requestData = {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (bio != null) 'bio': bio,
        if (tags != null) 'tags': tags,
        if (interests != null) 'interests': interests,
      };
      
      debugPrint('准备发送更新用户信息请求:');
      debugPrint('请求地址: /api/app/user/update');
      debugPrint('请求数据: $requestData');
      
      final response = await _dio.post('/api/app/user/update', data: requestData);
      
      debugPrint('更新用户信息响应: ${response.statusCode}');
      debugPrint('响应数据: ${response.data}');
      
      return ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      debugPrint('更新用户信息异常: ${e.type} ${e.message}');
      debugPrint('错误响应: ${e.response?.statusCode} ${e.response?.data}');
      
      return ApiResponse(
        code: e.response?.statusCode ?? 500,
        message: e.response?.data?['message'] ?? e.response?.statusMessage ?? '网络请求失败',
      );
    } catch (e) {
      debugPrint('更新用户信息未知异常: $e');
      return ApiResponse(code: 500, message: '未知错误: $e');
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
    bool? stream = false,
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
    
          'user_token': token,
          'user_id': userId.toString(),
          'provider': 'dify',
          'stream': stream ?? false,
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
  
  // 新增的流式请求方法
  Future<void> sendWorkflowRequest({
        required String agentId,
    required String agentName,
    required String agentPrompt,
    required String prompt,
    required String userId,
    required List<Map<String, String>> chatHistory,
    required String conversationId,
    required Function(String event, Map<String, dynamic> data) onEvent,
    required Function(String error) onError,
    required Function() onDone,
    List<Map<String, dynamic>>? files,
  }) async {
    try {
      debugPrint('发送流式工作流请求');
      
      final token = await Storage.getToken();
      if (token == null) {
        onError('请先登录');
        return;
      }
      print('agentId: $agentId');
      print('agentName: $agentName');
      print('agentPrompt: $agentPrompt');
      print('prompt: $prompt');
      print('userId: $userId');
      print('chatHistory: $chatHistory');
      print('conversationId: $conversationId');
      // 构建请求数据
      final requestData = {
        'inputs': {
          'query': prompt,
          'user_token': token,
          'user_id': userId,
          'chat_history_message': chatHistory.isNotEmpty 
              ? jsonEncode(chatHistory) 
              : 'system: 你是一个有帮助的AI助手\n',
        },
        'agent_id': agentId,
        'agent_name': agentName,
        'agent_prompt': agentPrompt,
        'user': userId,
        'conversation_id': conversationId,
      };
      
      // 如果有文件，添加到请求中
      if (files != null && files.isNotEmpty) {
        requestData['files'] = files;
      }
      
      debugPrint('工作流请求数据: $requestData');
      
      // 创建Dio实例但不设置baseUrl，因为SSE连接方式不同
      final dio = Dio(
        BaseOptions(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
          sendTimeout: const Duration(seconds: 600),
          receiveTimeout: const Duration(seconds: 600),
        ),
      );
      
      final response = await dio.post(
        '$baseUrl/chat/v1/workflows/run',
        data: requestData,
      );
      
      debugPrint('工作流响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final stream = response.data.stream as Stream<List<int>>;
        
        // 处理SSE流
        String buffer = '';
        bool workflowFinished = false;
        
        await for (final chunk in stream) {
          final String text = utf8.decode(chunk);
          buffer += text;
          
          // SSE格式为"data: {json数据}\n\n"
          final lines = buffer.split('\n\n');
          if (lines.length > 1) {
            for (int i = 0; i < lines.length - 1; i++) {
              final line = lines[i].trim();
              if (line.startsWith('data: ')) {
                final jsonStr = line.substring(6);
                try {
                  final data = jsonDecode(jsonStr) as Map<String, dynamic>;
                  final event = data['event'] as String?;
                  
                  if (event != null) {
                    final eventData = data['data'] as Map<String, dynamic>;
                    onEvent(event, eventData);
                    
                    // 检查是否是工作流结束事件
                    if (event == 'workflow_finished') {
                      debugPrint('工作流执行完成: ${eventData['outputs']}');
                      workflowFinished = true;
                      
                      // 调用完成回调，确保UI即时更新
                      Future.delayed(const Duration(milliseconds: 100), () {
                        onDone();
                      });
                      
                      break;
                    }
                  }
                } catch (e) {
                  debugPrint('解析SSE数据失败: $e, 数据: $jsonStr');
                }
              }
            }
            buffer = lines.last;
            
            // 如果工作流已完成，跳出循环
            if (workflowFinished) {
              break;
            }
          }
        }
        
        // 如果工作流没有显式完成但流结束了，也调用完成回调
        if (!workflowFinished) {
          onDone();
        }
      } else {
        onError('请求失败，状态码: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('工作流请求异常: ${e.type} ${e.message}');
      onError(e.response?.data?['message'] ?? '请求失败，请稍后再试');
    } catch (e) {
      debugPrint('工作流请求未知异常: $e');
      onError('发生未知错误: $e');
    }
  }

  // 用于测试的模拟流式请求，当实际接口不可用时可使用
  Future<void> sendMockWorkflowRequest({
    required String agentId,
    required String agentName,
    required String agentPrompt,
    required String prompt,
    required String userId,
    required List<Map<String, String>> chatHistory,
    required String conversationId,
    required Function(String event, Map<String, dynamic> data) onEvent,
    required Function(String error) onError,
    required Function() onDone,
  }) async {
    try {
      // 模拟启动工作流
      onEvent('workflow_started', {
        'id': 'mock-${DateTime.now().millisecondsSinceEpoch}',
        'workflow_id': 'mock-workflow',
        'sequence_number': 1,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 模拟节点开始
      onEvent('node_started', {
        'id': 'mock-node-${DateTime.now().millisecondsSinceEpoch}',
        'node_id': 'mock-node',
        'node_type': 'llm',
        'title': '回复生成',
        'index': 0,
        'predecessor_node_id': null,
        'inputs': {'query': prompt},
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 生成回复文本
      final String response = '我收到了您的问题: "$prompt"。这是一个很好的问题，让我来回答：';
      final words = response.split(' ');
      
      // 模拟文本流
      for (var word in words) {
        await Future.delayed(const Duration(milliseconds: 100));
        onEvent('text_chunk', {
          'text': '$word ',
          'from_variable_selector': ['mock', 'text'],
        });
      }
      
      // 根据prompt提供不同的回复
      if (prompt.contains('旅行') || prompt.contains('出行')) {
        final locations = ['北京', '上海', '广州', '深圳', '杭州', '成都', '重庆', '西安'];
        
        for (var location in locations) {
          await Future.delayed(const Duration(milliseconds: 150));
          onEvent('text_chunk', {
            'text': '\n$location是个不错的选择，',
            'from_variable_selector': ['mock', 'text'],
          });
          
          await Future.delayed(const Duration(milliseconds: 150));
          onEvent('text_chunk', {
            'text': '那里有很多著名景点和美食。',
            'from_variable_selector': ['mock', 'text'],
          });
        }
      } else {
        // 通用回复
        await Future.delayed(const Duration(milliseconds: 300));
        onEvent('text_chunk', {
          'text': '\n\n希望这个回答对您有所帮助！如果您有更多问题，请随时提出。',
          'from_variable_selector': ['mock', 'text'],
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 节点完成
      onEvent('node_finished', {
        'id': 'mock-node-${DateTime.now().millisecondsSinceEpoch}',
        'node_id': 'mock-node',
        'status': 'succeeded',
        'outputs': {'summary': '这是一个关于${prompt.contains('旅行') ? '旅行建议' : '一般问题'}的回答'},
        'elapsed_time': 2.5,
        'execution_metadata': {
          'total_tokens': 150,
          'total_price': 0.001,
          'currency': 'USD',
        },
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 工作流完成
      onEvent('workflow_finished', {
        'id': 'mock-${DateTime.now().millisecondsSinceEpoch}',
        'workflow_id': 'mock-workflow',
        'status': 'succeeded',
        'outputs': {'summary': '这是一个关于${prompt.contains('旅行') ? '旅行建议' : '一般问题'}的回答'},
        'elapsed_time': 3.0,
        'total_tokens': 150,
        'total_steps': 1,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'finished_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      
      onDone();
    } catch (e) {
      debugPrint('模拟流式请求异常: $e');
      onError('模拟请求失败: $e');
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

  // 上传图片
  Future<ApiResponse<List<String>>> uploadImages(List<String> imagePaths) async {
    try {
      final token = await Storage.getToken();
      if (token == null) {
        return ApiResponse(code: 401, message: '请先登录');
      }
      
      debugPrint('准备上传图片: $imagePaths');
      final formData = FormData();
      
      for (var path in imagePaths) {
        final fileName = path.split('/').last;
        debugPrint('添加文件: $fileName 路径: $path');
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(path, filename: fileName),
          ),
        );
      }
      
      debugPrint('发送图片上传请求...');
      final response = await _dio.post(
        '/api/upload/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      debugPrint('图片上传响应: ${response.statusCode}');
      debugPrint('图片上传响应数据: ${response.data}');
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        List<String> imageUrls = [];
        if (response.data['data'] is List) {
          // 处理列表形式的URL
          imageUrls = List<String>.from(response.data['data']);
          debugPrint('服务器返回的URL列表: $imageUrls');
        } else if (response.data['data'] is String) {
          // 处理单个URL作为字符串返回的情况
          imageUrls = [response.data['data']];
          debugPrint('服务器返回的单个URL: ${response.data['data']}');
        } else if (response.data['data'] is Map) {
          // 处理某些情况下返回的可能是包含URL的对象
          final dataMap = response.data['data'] as Map;
          if (dataMap.containsKey('url')) {
            imageUrls = [dataMap['url'].toString()];
            debugPrint('从对象中提取的URL: ${dataMap['url']}');
          }
        }
        
        // 直接返回服务器提供的URL，不进行额外处理
        debugPrint('上传成功，服务器返回的原始URLs: $imageUrls');
        return ApiResponse(
          code: 200,
          message: response.data['message'] ?? '上传成功',
          data: imageUrls,
        );
      }
      
      debugPrint('上传失败，响应: ${response.data}');
      return ApiResponse(
        code: response.data['code'] ?? 400,
        message: response.data['message'] ?? '上传失败',
      );
    } on DioException catch (e) {
      debugPrint('上传图片异常: ${e.type} ${e.message}');
      debugPrint('上传图片错误详情: ${e.response?.statusCode} ${e.response?.data}');
      return ApiResponse(
        code: e.response?.statusCode ?? 500,
        message: e.response?.data?['message'] ?? e.response?.statusMessage ?? '网络请求失败',
      );
    } catch (e) {
      debugPrint('上传图片未知异常: $e');
      return ApiResponse(code: 500, message: '未知错误: $e');
    }
  }

  // 更新用户头像
  Future<ApiResponse<Map<String, dynamic>>> updateUserAvatar(String avatarUrl) async {
    try {
      debugPrint('更新用户头像: $avatarUrl');
      final response = await _dio.post('/api/app/user/update', data: {
        'avatar_url': avatarUrl,
      });
      
      debugPrint('更新头像响应: ${response.statusCode}');
      debugPrint('更新头像响应数据: ${response.data}');
      
      return ApiResponse.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      debugPrint('更新头像异常: ${e.type} ${e.message}');
      debugPrint('更新头像错误详情: ${e.response?.statusCode} ${e.response?.data}');
      return ApiResponse(
        code: e.response?.statusCode ?? 500,
        message: e.response?.data?['message'] ?? e.response?.statusMessage ?? '网络请求失败',
      );
    } catch (e) {
      debugPrint('更新头像未知异常: $e');
      return ApiResponse(code: 500, message: '未知错误: $e');
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