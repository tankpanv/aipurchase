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

  Future<void> createOrder(int addressId, List<Map<String, dynamic>> items, {String? remarks}) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _apiService.post(
        '/api/app/user/orders',
        data: {
          'address_id': addressId,
          'items': items,
          if (remarks != null) 'remarks': remarks,
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess) {
        final orderNo = apiResponse.data!['order_no'];
        
        Get.back(); // 关闭地址选择页面
        Get.back(); // 关闭确认订单对话框
        Get.snackbar('成功', '订单创建成功');
        
        // 跳转到订单详情页
        Get.toNamed(Routes.ORDER_DETAIL, parameters: {'orderNo': orderNo});
      } else {
        error.value = apiResponse.message;
        Get.snackbar('失败', apiResponse.message);
      }
    } catch (e) {
      error.value = e.toString();
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

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        final responseData = apiResponse.data!;
        final List<dynamic> orderList = responseData['items'] ?? [];
        
        // 添加日志以便调试
        debugPrint('订单列表数据: $orderList');
        
        final List<Order> newOrders = [];
        for (var item in orderList) {
          try {
            if (item is Map<String, dynamic>) {
              final order = Order.fromJson(item);
              newOrders.add(order);
            } else {
              debugPrint('无效的订单数据格式: $item');
            }
          } catch (e) {
            debugPrint('解析订单数据失败: $e');
            continue;
          }
        }
        
        orders.addAll(newOrders);
        totalPages.value = responseData['pages'] ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
        currentPage.value++;
      } else {
        error.value = apiResponse.message;
        Get.snackbar('失败', apiResponse.message);
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('错误', '获取订单列表失败：$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Order> getOrderDetail(String orderNo) async {
    try {
      final response = await _apiService.get('/api/app/user/orders/$orderNo');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.isSuccess) {
        return Order.fromJson(apiResponse.data!);
      } else {
        throw apiResponse.message;
      }
    } catch (e) {
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