import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../routes/app_pages.dart';

class CartController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool allSelected = true.obs;
  final RxDouble totalAmount = 0.0.obs;

  // 获取已选中的商品
  List<CartItem> get selectedItems => items.where((item) => item.selected).toList();

  @override
  void onInit() {
    super.onInit();
    fetchCartItems();
  }

  // 获取购物车列表
  Future<void> fetchCartItems() async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/api/app/user/cart', queryParameters: {
        'include': 'product',
      });
      developer.log('获取购物车列表响应: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        final data = response.data['data'];
        if (data != null) {
          if (data is List) {
            // 如果data直接是数组
            items.value = data.map((json) => CartItem.fromJson(json)).toList();
          } else if (data['items'] != null) {
            // 如果data包含items数组
            final List<dynamic> items = data['items'];
            this.items.value = items.map((json) => CartItem.fromJson(json)).toList();
          } else {
            // 如果data是单个商品
            final item = CartItem.fromJson(data);
            if (!items.any((existingItem) => existingItem.id == item.id)) {
              items.add(item);
            }
          }
          _updateTotalAmount();
          _updateAllSelected();
        }
      } else {
        final message = response.data?['message'] ?? '获取购物车列表失败';
        developer.log('获取购物车列表失败: $message, 响应数据: ${response.data}');
        Get.snackbar('错误', message);
      }
    } catch (e) {
      developer.log('获取购物车列表异常: $e');
      // Get.snackbar('错误', '获取购物车列表失败');
    } finally {
      isLoading.value = false;
    }
  }

  // 添加商品到购物车
  Future<bool> addToCart(int productId, int quantity, {bool navigateToCart = true}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(
        '/api/app/user/cart',
        data: {
          'product_id': productId,
          'quantity': quantity,
        },
      );
      
      developer.log('添加购物车响应: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        final data = response.data['data'];
        if (data != null) {
          final item = CartItem.fromJson(data);
          final index = items.indexWhere((existingItem) => existingItem.id == item.id);
          if (index >= 0) {
            items[index] = item;
          } else {
            items.add(item);
          }
          _updateTotalAmount();
          _updateAllSelected();
        }
        Get.snackbar('成功', '添加到购物车成功');
        if (navigateToCart) {
          Get.toNamed(Routes.CART);
        }
        return true;
      } else {
        final message = response.data?['message'] ?? '添加到购物车失败';
        Get.snackbar('失败', message);
        return false;
      }
    } catch (e) {
      developer.log('添加购物车异常: $e');
      Get.snackbar('错误', '添加到购物车失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 更新购物车商品
  Future<bool> updateCartItem(int id, {int? quantity, bool? selected}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put(
        '/api/app/user/cart/$id',
        data: {
          if (quantity != null) 'quantity': quantity,
          if (selected != null) 'selected': selected,
        },
      );
      
      developer.log('更新购物车响应: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        await fetchCartItems();
        Get.snackbar('成功', '更新成功');
        return true;
      } else {
        final message = response.data?['message'] ?? '更新失败';
        Get.snackbar('失败', message);
        return false;
      }
    } catch (e) {
      developer.log('更新购物车异常: $e');
      Get.snackbar('错误', '更新购物车失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 删除购物车商品
  Future<bool> removeFromCart(int id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('/api/app/user/cart/$id');
      
      developer.log('删除购物车商品响应: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        await fetchCartItems();
        Get.snackbar('成功', '删除成功');
        return true;
      } else {
        final message = response.data?['message'] ?? '删除失败';
        Get.snackbar('失败', message);
        return false;
      }
    } catch (e) {
      developer.log('删除购物车商品异常: $e');
      Get.snackbar('错误', '删除失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 批量更新选中状态
  Future<bool> updateBatchSelected(bool selected) async {
    try {
      isLoading.value = true;
      final itemIds = items.map((item) => item.id!).toList();
      final response = await _apiService.put(
        '/api/app/user/cart/batch',
        data: {
          'selected': selected,
          'item_ids': itemIds,
        },
      );
      
      developer.log('批量更新选中状态响应: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        await fetchCartItems();
        return true;
      } else {
        final message = response.data?['message'] ?? '更新失败';
        Get.snackbar('失败', message);
        return false;
      }
    } catch (e) {
      developer.log('批量更新选中状态异常: $e');
      Get.snackbar('错误', '更新失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 清空购物车
  Future<bool> clearCart() async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('/api/app/user/cart');
      
      developer.log('清空购物车响应: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        items.clear();
        _updateTotalAmount();
        Get.snackbar('成功', '清空购物车成功');
        return true;
      } else {
        final message = response.data?['message'] ?? '清空购物车失败';
        Get.snackbar('失败', message);
        return false;
      }
    } catch (e) {
      developer.log('清空购物车异常: $e');
      Get.snackbar('错误', '清空购物车失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 更新总金额
  void _updateTotalAmount() {
    totalAmount.value = items
        .where((item) => item.selected)
        .fold(0, (sum, item) => sum + item.totalPrice);
  }

  // 更新全选状态
  void _updateAllSelected() {
    allSelected.value = items.isNotEmpty && items.every((item) => item.selected);
  }

  // 切换全选状态
  void toggleAllSelected() {
    final newStatus = !allSelected.value;
    updateBatchSelected(newStatus);
  }

  // 移除已选中的商品
  Future<void> removeSelectedItems() async {
    try {
      isLoading.value = true;
      final selectedIds = selectedItems.map((item) => item.id!).toList();
      
      final response = await _apiService.delete(
        '/api/app/user/cart/batch',
        data: {
          'item_ids': selectedIds,
        },
      );
      
      developer.log('移除已选商品响应: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        items.removeWhere((item) => selectedIds.contains(item.id));
        _updateTotalAmount();
        _updateAllSelected();
      } else {
        final message = response.data?['message'] ?? '移除商品失败';
        Get.snackbar('失败', message);
      }
    } catch (e) {
      developer.log('移除已选商品异常: $e');
      Get.snackbar('错误', '移除商品失败');
    } finally {
      isLoading.value = false;
    }
  }
} 