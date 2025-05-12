import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/product_detail_controller.dart';
import '../../../models/product_model.dart';
import '../../../models/product_detail.dart';
import '../../../routes/app_pages.dart';

class ProductDetailView extends GetView<ProductDetailController> {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value && controller.product.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.r, color: AppColors.textSecondary),
                SizedBox(height: 16.h),
                Text(
                  controller.error.value,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    if (Get.arguments is ProductSimple) {
                      final product = Get.arguments as ProductSimple;
                      controller.fetchProductDetails(product.id);
                    } else if (Get.arguments is Map && Get.arguments['productId'] != null) {
                      controller.fetchProductDetails(Get.arguments['productId']);
                    }
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final product = controller.product.value;
        if (product == null) {
          return const Center(child: Text('商品不存在'));
        }

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(product),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceSection(product),
                      _buildDescriptionSection(product),
                      _buildMerchantSection(product),
                      SizedBox(height: 100.h), // 底部占位
                    ],
                  ),
                ),
              ],
            ),
            _buildBottomBar(),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar(ProductDetail product) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          product.mainImageUrl ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported, size: 64.r),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          onPressed: () => Get.toNamed(Routes.CART),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildPriceSection(ProductDetail product) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '¥${product.originalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textHint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            product.name,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.local_offer, size: 16.r, color: AppColors.secondary),
              SizedBox(width: 4.w),
              Text(
                '库存: ${product.stock}${product.unit ?? '件'}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              if (product.promotionTags != null && product.promotionTags!.isNotEmpty) ...[
                SizedBox(width: 16.w),
                Icon(Icons.local_activity, size: 16.r, color: AppColors.secondary),
                SizedBox(width: 4.w),
                Text(
                  product.promotionTags!.join('、'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (product.categories != null && product.categories!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  Icon(Icons.category, size: 16.r, color: AppColors.secondary),
                  SizedBox(width: 4.w),
                  Text(
                    product.categories!.map((cat) => cat['name'] as String).join(' > '),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ProductDetail product) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(16.r),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '商品详情',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (product.spec != null && product.spec!.isNotEmpty)
            ..._buildSpecification(product.spec!),
          if (product.tags != null && product.tags!.isNotEmpty)
            ..._buildTags(product.tags!),
          if (product.images != null && product.images!.isNotEmpty)
            ..._buildDetailImages(product.images!),
        ],
      ),
    );
  }

  List<Widget> _buildSpecification(String spec) {
    return [
      SizedBox(height: 16.h),
      Text(
        '规格参数',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(height: 8.h),
      Text(
        spec,
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textSecondary,
        ),
      ),
    ];
  }

  List<Widget> _buildDetailImages(List<Map<String, dynamic>> images) {
    return [
      SizedBox(height: 16.h),
      Text(
        '商品图片',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(height: 8.h),
      ...images.map((image) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Image.network(
          image['url'] as String,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200.h,
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported, size: 64.r),
            );
          },
        ),
      )),
    ];
  }

  List<Widget> _buildTags(List<String> tags) {
    return [
      SizedBox(height: 16.h),
      Text(
        '商品标签',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(height: 8.h),
      Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: tags.map((tag) => Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.primary,
            ),
          ),
        )).toList(),
      ),
    ];
  }

  Widget _buildMerchantSection(ProductDetail product) {
    if (product.merchant == null) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(16.r),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.store,
              color: AppColors.primary,
              size: 24.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.merchantName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () {
                    controller.addToCart();
                  },
                  child: const Text('加入购物车'),
                )),
              ),
              SizedBox(width: 16.w),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => controller.decrementQuantity(),
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      constraints: BoxConstraints(minWidth: 40.w),
                      alignment: Alignment.center,
                      child: Obx(() => Text(
                        '${controller.quantity.value}',
                        style: TextStyle(fontSize: 16.sp),
                      )),
                    ),
                    IconButton(
                      onPressed: () => controller.incrementQuantity(),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
