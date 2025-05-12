import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/product_detail.dart';
import '../services/api_service.dart';
import './cart_controller.dart';

class ProductDetailController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final Rx<ProductDetail?> product = Rx<ProductDetail?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt quantity = 1.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is ProductSimple) {
      final product = Get.arguments as ProductSimple;
      fetchProductDetails(product.id);
    } else if (Get.arguments is Map && Get.arguments['productId'] != null) {
      final productId = Get.arguments['productId'];
      fetchProductDetails(productId);
    } else {
      error.value = '产品ID不能为空';
      isLoading.value = false;
    }
  }

  Future<void> fetchProductDetails(int productId) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      developer.log('正在获取产品详情，ID: $productId');
      final response = await _apiService.get('/api/app/products/$productId');
      
      developer.log('API响应数据: ${response.data}');
      
      if (response.data != null && response.data['code'] == 200) {
        try {
          product.value = ProductDetail.fromJson(response.data);
          developer.log('产品数据解析成功: ${product.value?.toJson()}');
        } catch (e) {
          developer.log('产品数据解析错误: $e');
          error.value = '数据格式错误';
        }
      } else {
        developer.log('API响应中没有找到产品数据或状态码不正确');
        error.value = response.data?['message'] ?? '未找到产品信息';
      }
    } catch (e) {
      developer.log('获取产品详情失败: $e');
      error.value = '获取产品信息失败，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }

  void incrementQuantity() {
    if (product.value != null && quantity.value < product.value!.stock) {
      quantity.value++;
    }
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  Future<bool> addToCart() async {
    if (product.value == null) {
      developer.log('添加购物车失败: 商品为空');
      return false;
    }
    
    try {
      isLoading.value = true;
      developer.log('准备添加商品到购物车: id=${product.value!.id}, quantity=${quantity.value}');
      
      final cartController = Get.find<CartController>();
      final success = await cartController.addToCart(
        product.value!.id,
        quantity.value,
      );
      
      if (success) {
        Get.snackbar('成功', '已加入购物车');
        return true;
      } else {
        Get.snackbar('失败', '加入购物车失败');
        return false;
      }
    } catch (e) {
      developer.log('添加购物车异常: $e');
      Get.snackbar('错误', '加入购物车失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
} 