import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/address_controller.dart';
import '../controllers/order_controller.dart';
import 'dart:developer' as developer;

class ProductActionButtons extends StatelessWidget {
  final int productId;
  
  const ProductActionButtons({
    super.key,
    required this.productId,
  });

  Future<void> _addToCart() async {
    try {
      final cartController = Get.find<CartController>();
      developer.log('准备添加商品到购物车: id=$productId, quantity=1');
      
      final success = await cartController.addToCart(
        productId,
        1, // 默认数量为1
        navigateToCart: true, // 成功后跳转到购物车
      );
      
      if (success) {
        Get.snackbar('成功', '已加入购物车');
      } else {
        Get.snackbar('失败', '加入购物车失败');
      }
    } catch (e) {
      developer.log('添加购物车异常: $e');
      Get.snackbar('错误', '加入购物车失败');
    }
  }

  Future<void> _buyNow() async {
    try {
      // 获取地址控制器
      final addressController = Get.put(AddressController());
      final orderController = Get.put(OrderController());

      // 获取地址列表
      await addressController.fetchAddresses();

      // 获取默认地址
      final defaultAddress = addressController.addresses.firstWhereOrNull((addr) => addr.isDefault);
      
      if (defaultAddress == null) {
        Get.snackbar('提示', '请先设置默认收货地址');
        Get.toNamed('/address-list');
        return;
      }

      // 创建订单项
      final items = [{
        'product_id': productId,
        'quantity': 1,
      }];

      // 创建订单
      await orderController.createOrder(
        defaultAddress.id!,
        items,
      );

    } catch (e) {
      developer.log('立即购买异常: $e');
      Get.snackbar('错误', '购买失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () => Get.toNamed(
            '/product/detail',
            arguments: {'productId': productId},
          ),
          child: const Text('查看详情'),
        ),
        TextButton(
          onPressed: _addToCart,
          child: const Text('加入购物车'),
        ),
        ElevatedButton(
          onPressed: _buyNow,
          child: const Text('立即购买'),
        ),
      ],
    );
  }
} 