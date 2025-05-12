import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../models/product_model.dart';
import '../routes/app_pages.dart';

class ProductCard extends StatelessWidget {
  final ProductSimple product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(Routes.PRODUCT_DETAIL, arguments: {'productId': product.id}),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SizedBox(
          height: 200.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 110.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.r),
                    topRight: Radius.circular(8.r),
                  ),
                  image: product.mainImageUrl != null && product.mainImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.mainImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: product.mainImageUrl == null || product.mainImageUrl!.isEmpty
                  ? Icon(
                      product.getProductIcon(),
                      size: 48.r,
                      color: AppColors.primary,
                    )
                  : null,
              ),
              
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      
                      Row(
                        children: [
                          Text(
                            '¥${product.price.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '¥${product.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textHint,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      
                      if (product.discount != null && product.discount!.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: product.discount!.contains('新客') 
                                ? AppColors.secondary.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            product.discount!,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: product.discount!.contains('新客') 
                                  ? AppColors.secondary
                                  : AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 