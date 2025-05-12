import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/product_list_controller.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/empty_placeholder.dart';

class ProductListView extends GetView<ProductListController> {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.title ?? '商品列表'),
      ),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Obx(() {
          if (controller.isLoading.value && controller.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.hasError.value && controller.products.isEmpty) {
            return EmptyPlaceholder(
              icon: Icons.error_outline,
              message: controller.errorMessage.value,
              onRefresh: () => controller.fetchProducts(refresh: true),
            );
          }

          if (controller.products.isEmpty) {
            return EmptyPlaceholder(
              icon: Icons.shopping_bag_outlined,
              message: '暂无商品',
              onRefresh: () => controller.fetchProducts(refresh: true),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
                  !controller.isLoadingMore.value &&
                  controller.hasMore.value) {
                controller.fetchProducts();
              }
              return true;
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 16.h,
                      crossAxisSpacing: 16.w,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ProductCard(
                          product: controller.products[index],
                        );
                      },
                      childCount: controller.products.length,
                    ),
                  ),
                ),
                if (controller.isLoadingMore.value)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
} 