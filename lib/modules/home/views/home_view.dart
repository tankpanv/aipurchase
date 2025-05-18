import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../home_controller.dart';
import '../../../widgets/menu_grid_item.dart';
import '../../../widgets/product_card.dart';
import '../../../models/product_model.dart';
import '../../../routes/app_pages.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController controller = Get.find<HomeController>();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        controller.fetchRecommendations();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAllData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 顶部搜索栏
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              
              // 菜单网格
              SliverToBoxAdapter(
                child: _buildMenuGrid(),
              ),
              
              // 特价团购
              SliverToBoxAdapter(
                child: _buildSpecialOffers(),
              ),
              
              // 推荐商品
              SliverToBoxAdapter(
                child: _buildRecommendations(),
              ),
              
              // 加载更多指示器
              SliverToBoxAdapter(
                child: Obx(() => controller.isLoadingMore.value
                  ? Container(
                      height: 50.h,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    )
                  : const SizedBox.shrink()
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 顶部搜索栏
  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        children: [
          // 搜索框
          Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: '咸蛋黄油条',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14.sp,
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        Get.toNamed(
                          Routes.SEARCH,
                          arguments: {'keyword': value},
                        );
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final keyword = controller.searchController.text.trim();
                    if (keyword.isNotEmpty) {
                      Get.toNamed(
                        Routes.SEARCH,
                        arguments: {'keyword': keyword},
                      );
                    }
                  },
                  child: Container(
                    height: 40.h,
                    width: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Center(
                      child: Text(
                        '搜索',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 菜单网格
  Widget _buildMenuGrid() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.0,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 0,
        ),
        itemCount: controller.menuItems.length,
        itemBuilder: (context, index) {
          final item = controller.menuItems[index];
          return MenuGridItem(
            name: item['name'] as String,
            icon: item['icon'] as IconData,
            onTap: () {
              // 跳转到商品列表页，传递 productType 和可选的 keyword 参数
              Get.toNamed(
                Routes.PRODUCTS,
                arguments: {
                  'productType': item['productType'],
                  if (item['keyword'] != null) 'keyword': item['keyword'],
                  'title': item['name'],
                },
              );
            },
          );
        },
      ),
    );
  }

  // 特价团购
  Widget _buildSpecialOffers() {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '特价团',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '爆款热抢中',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '更多 >',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // 产品列表
          Obx(() {
            if (controller.isLoading.value && controller.specialOffers.isEmpty) {
              return Container(
                height: 220.h,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            }
            
            if (controller.hasError.value && controller.specialOffers.isEmpty) {
              return Container(
                height: 220.h,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 40.r, color: AppColors.textSecondary),
                    SizedBox(height: 8.h),
                    Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: controller.fetchSpecialOffers,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }
            
            return SizedBox(
              height: 220.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.specialOffers.length,
                itemBuilder: (context, index) {
                  final productModel = controller.specialOffers[index];
                  return SizedBox(
                    width: 160.w,
                    child: ProductCard(
                      product: productModel,
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // 推荐商品
  Widget _buildRecommendations() {
    return Container(
      margin: EdgeInsets.only(top: 8.h, bottom: 16.h),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 外卖神抢手
          Row(
            children: [
              Text(
                '外卖神抢手',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '大牌加倍补',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // 产品网格
          Obx(() {
            if (controller.isLoading.value && controller.recommendations.isEmpty) {
              return Container(
                height: 200.h,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            }
            
            if (controller.hasError.value && controller.recommendations.isEmpty) {
              return Container(
                height: 200.h,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 40.r, color: AppColors.textSecondary),
                    SizedBox(height: 8.h),
                    Text(
                      controller.errorMessage.value,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: () => controller.fetchRecommendations(refresh: true),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
              ),
              itemCount: controller.recommendations.length,
              itemBuilder: (context, index) {
                final productModel = controller.recommendations[index];
                return ProductCard(
                  product: productModel,
                );
              },
            );
          }),
        ],
      ),
    );
  }
} 