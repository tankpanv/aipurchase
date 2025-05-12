import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/search_result_controller.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/empty_placeholder.dart';

class SearchResultView extends GetView<SearchResultController> {
  const SearchResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 36.h,
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: TextField(
            controller: TextEditingController(text: controller.keyword),
            decoration: InputDecoration(
              hintText: '搜索商品',
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 14.sp,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              suffixIcon: controller.keyword?.isNotEmpty == true
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textHint),
                    onPressed: () {
                      controller.updateKeyword('');
                      controller.searchProducts(refresh: true);
                    },
                  )
                : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                controller.updateKeyword(value);
                controller.searchProducts(refresh: true);
              }
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: _buildSortBar(),
        ),
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
              onRefresh: () => controller.searchProducts(refresh: true),
            );
          }

          if (controller.products.isEmpty) {
            return EmptyPlaceholder(
              icon: Icons.search_off_outlined,
              message: '未找到相关商品',
              onRefresh: () => controller.searchProducts(refresh: true),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200 &&
                  !controller.isLoadingMore.value &&
                  controller.hasMore.value) {
                controller.searchProducts();
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

  Widget _buildSortBar() {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      color: Colors.white,
      child: Row(
        children: [
          _buildSortButton(
            text: '综合',
            onTap: () => controller.updateSort('created_at', isAsc: false),
          ),
          SizedBox(width: 24.w),
          _buildSortButton(
            text: '销量',
            onTap: () => controller.updateSort('sales', isAsc: false),
          ),
          SizedBox(width: 24.w),
          _buildPriceSortButton(),
          const Spacer(),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildSortButton({
    required String text,
    required VoidCallback onTap,
  }) {
    const isSelected = false; // 可以根据实际排序状态设置
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPriceSortButton() {
    return GestureDetector(
      onTap: () {
        final isAsc = controller.order != 'asc';
        controller.updateSort('price', isAsc: isAsc);
      },
      child: Row(
        children: [
          Text(
            '价格',
            style: TextStyle(
              fontSize: 14.sp,
              color: controller.sort == 'price'
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            controller.sort == 'price' && controller.order == 'asc'
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: 16.r,
            color: controller.sort == 'price'
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: () {
        _showFilterDialog();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '筛选',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.filter_list,
              size: 16.r,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    double? minPrice = controller.priceMin;
    double? maxPrice = controller.priceMax;

    Get.dialog(
      AlertDialog(
        title: const Text('价格区间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: minPrice?.toString() ?? '',
                    ),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '最低价',
                      prefixText: '¥',
                    ),
                    onChanged: (value) {
                      minPrice = double.tryParse(value);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: const Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: maxPrice?.toString() ?? '',
                    ),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '最高价',
                      prefixText: '¥',
                    ),
                    onChanged: (value) {
                      maxPrice = double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.updatePriceRange(minPrice, maxPrice);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 