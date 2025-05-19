import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../routes/app_pages.dart';
import '../models/api_response.dart';
import 'package:flutter/material.dart';

class OrderController extends GetxController {
  final _apiService = Get.find<ApiService>();
  final orders = <Order>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasMore = true.obs;
  bool _isLoadingOrderDetail = false;

  Future<void> createOrder(int addressId, List<Map<String, dynamic>> items, {String? remarks}) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // 验证输入参数
      if (addressId <= 0) {
        throw '无效的地址ID: $addressId';
      }
      
      if (items.isEmpty) {
        throw '订单中没有商品';
      }
      
      // 检查每个商品条目
      for (var item in items) {
        if (!item.containsKey('product_id') || item['product_id'] == null) {
          throw '商品缺少产品ID';
        }
        if (!item.containsKey('quantity') || item['quantity'] == null || item['quantity'] <= 0) {
          throw '商品数量无效';
        }
      }
      
      debugPrint('[log] 创建订单请求数据: address_id=$addressId, items=$items, remarks=$remarks');
      
      // 构建请求数据
      final data = {
        'address_id': addressId,
        'items': items,
      };
      
      // 如果有备注，添加到请求数据
      if (remarks != null && remarks.trim().isNotEmpty) {
        data['remarks'] = remarks.trim();
      }
      
      final response = await _apiService.post(
        '/api/app/user/orders',
        data: data,
      );
      
      debugPrint('[log] 创建订单响应状态码: ${response.statusCode}');
      debugPrint('[log] 创建订单响应数据: ${response.data}');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        final orderData = apiResponse.data!;
        
        if (!orderData.containsKey('order_no')) {
          debugPrint('[log] 创建订单响应缺少order_no字段: $orderData');
          throw '订单数据格式错误: 缺少订单号';
        }
        
        final orderNo = orderData['order_no'];
        
        Get.back(); // 关闭地址选择页面
        Get.back(); // 关闭确认订单对话框
        Get.snackbar('成功', '订单创建成功', duration: const Duration(seconds: 2));
        
        // 等待snackbar显示完成再跳转
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 跳转到订单详情页
        Get.toNamed(Routes.ORDER_DETAIL, parameters: {'orderNo': orderNo});
      } else {
        error.value = apiResponse.message;
        debugPrint('[log] 创建订单失败: ${apiResponse.message}');
        Get.snackbar('失败', apiResponse.message);
      }
    } catch (e, stackTrace) {
      error.value = e.toString();
      debugPrint('[log] 创建订单异常: $e');
      debugPrint('[log] 异常堆栈: $stackTrace');
      Get.snackbar('错误', '创建订单失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrders({String? status, bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMore.value = true;
        orders.clear(); // 在刷新时清空列表
      }

      if (!hasMore.value && !refresh) return;

      if (currentPage.value == 1) {
        isLoading.value = true;
        error.value = '';
      }

      final response = await _apiService.get(
        '/api/app/user/orders',
        queryParameters: {
          'page': currentPage.value,
          'per_page': 10,
          if (status != null) 'status': status,
        },
      );

      // 添加更详细的响应数据日志
      debugPrint('订单API响应状态码: ${response.statusCode}');
      debugPrint('订单API响应数据: ${response.data}');

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        final responseData = apiResponse.data!;
        
        // 检查items字段是否存在
        if (!responseData.containsKey('items')) {
          debugPrint('API响应中缺少items字段: $responseData');
          error.value = '数据格式错误: 缺少items字段';
          return;
        }
        
        final List<dynamic> orderList = responseData['items'] ?? [];
        debugPrint('获取到${orderList.length}个订单');
        
        final List<Order> newOrders = [];
        for (var i = 0; i < orderList.length; i++) {
          try {
            final item = orderList[i];
            if (item is Map<String, dynamic>) {
              // 详细记录每个订单数据处理过程
              debugPrint('处理第${i+1}个订单: id=${item['id']}, orderNo=${item['order_no']}');
              
              // 验证关键字段
              if (!item.containsKey('id') || !item.containsKey('order_no')) {
                debugPrint('订单数据缺少关键字段: $item');
                continue;
              }
              
              // 检查items字段
              if (!item.containsKey('items')) {
                debugPrint('订单缺少items字段: ${item['order_no']}');
                continue;
              }
              
              // 检查items是否为List类型
              if (!(item['items'] is List)) {
                debugPrint('订单items字段不是List类型: ${item['items']}');
                continue;
              }
              
              final order = Order.fromJson(item);
              newOrders.add(order);
              debugPrint('订单添加成功: ${order.orderNo}');
            } else {
              debugPrint('无效的订单数据格式: $item');
            }
          } catch (e, stackTrace) {
            debugPrint('解析订单数据失败: $e');
            debugPrint('异常堆栈: $stackTrace');
            continue;
          }
        }
        
        debugPrint('成功解析${newOrders.length}个订单');
        orders.addAll(newOrders);
        totalPages.value = responseData['pages'] ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
        currentPage.value++;
      } else {
        error.value = apiResponse.message;
        debugPrint('API请求失败: ${apiResponse.message}');
        Get.snackbar('失败', apiResponse.message);
      }
    } catch (e, stackTrace) {
      error.value = e.toString();
      debugPrint('获取订单列表异常: $e');
      debugPrint('异常堆栈: $stackTrace');
      Get.snackbar('错误', '获取订单列表失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Order> getOrderDetail(String orderNo) async {
    try {
      debugPrint('[log] 获取订单详情: $orderNo');
      // 移除全局锁，允许并发请求，防止"请求正在处理中"异常
      // 添加延迟，避免UI渲染问题
      await Future.delayed(const Duration(milliseconds: 100));
      
      final response = await _apiService.get('/api/app/user/orders/$orderNo');
      
      // 记录API响应
      debugPrint('[log] 订单详情API响应状态码: ${response.statusCode}');
      debugPrint('[log] 订单详情API响应数据: ${response.data}');
      
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        // 检查关键字段
        final orderData = apiResponse.data!;
        
        debugPrint('Order原始数据: $orderData');
        
        // 验证关键字段存在性
        if (!orderData.containsKey('id') || !orderData.containsKey('order_no')) {
          debugPrint('[log] 订单详情数据缺少关键字段: $orderData');
          throw '订单数据格式错误: 缺少必要字段';
        }
        
        // 检查id是否为null
        if (orderData['id'] == null) {
          debugPrint('[log] 订单ID为null: $orderData');
          // 如果ID为null，添加默认值
          orderData['id'] = 0;
        }
        
        // 检查items字段
        if (!orderData.containsKey('items') || !(orderData['items'] is List)) {
          debugPrint('[log] 订单详情缺少有效的items字段: ${orderData['order_no']}');
          throw '订单数据格式错误: 缺少商品信息';
        }
        
        try {
          final order = Order.fromJson(orderData);
          debugPrint('[log] 订单详情解析成功: ${order.orderNo}');
          return order;
        } catch (e, stackTrace) {
          debugPrint('[log] 解析订单详情失败: $e');
          debugPrint('[log] 异常堆栈: $stackTrace');
          throw '解析订单数据失败: $e';
        }
      } else {
        debugPrint('[log] 获取订单详情失败: ${apiResponse.message}');
        throw apiResponse.message;
      }
    } catch (e, stackTrace) {
      debugPrint('[log] 获取订单详情异常: $e');
      debugPrint('[log] 异常堆栈: $stackTrace');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderNo) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.post('/api/app/user/orders/$orderNo/cancel');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess) {
        Get.snackbar('成功', '订单已取消');
        fetchOrders(refresh: true);
      } else {
        error.value = apiResponse.message;
        Get.snackbar('失败', apiResponse.message);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '取消订单失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmReceipt(String orderNo) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.post('/api/app/user/orders/$orderNo/confirm');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess) {
        Get.snackbar('成功', '已确认收货');
        fetchOrders(refresh: true);
      } else {
        error.value = apiResponse.message;
        Get.snackbar('失败', apiResponse.message);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '确认收货失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> payOrder(String orderNo) async {
    // 显示支付方式选择对话框
    Get.dialog(
      AlertDialog(
        title: const Text('选择支付方式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('微信支付'),
              onTap: () => _processPayment(orderNo, 'wechat'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: const Text('支付宝'),
              onTap: () => _processPayment(orderNo, 'alipay'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(String orderNo, String paymentMethod) async {
    try {
      Get.back(); // 关闭支付方式选择对话框
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.post(
        '/api/app/user/payments/create',
        data: {
          'order_no': orderNo,
          'payment_method': paymentMethod
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess) {
        Get.snackbar('成功', '支付成功');
        
        // 刷新订单列表
        fetchOrders(refresh: true);
        
        // 如果在订单详情页，刷新当前订单状态
        if (Get.currentRoute.contains('/order/detail')) {
          getOrderDetail(orderNo).then((updatedOrder) {
            // 通知订单详情页刷新
            Get.forceAppUpdate();
          });
        } else {
          // 如果不在订单详情页，返回到订单列表页
          Get.until((route) => !route.settings.name!.contains('/order/detail'));
        }
      } else {
        error.value = apiResponse.message;
        Get.snackbar('失败', apiResponse.message);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '支付失败：$e');
    } finally {
      isLoading.value = false;
    }
  }
} 