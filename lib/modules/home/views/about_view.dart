import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';

class AboutView extends GetView {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于我们'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 32.h),
              // App Logo
              Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.shopping_bag,
                  size: 60.r,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16.h),
              // App 名称
              Text(
                '智能导购',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              // 版本号
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 32.h),
              // 分割线
              const Divider(color: AppColors.divider),
              SizedBox(height: 32.h),
              // 关于内容
              Text(
                '智能导购是一款专注于为用户提供优质商品和服务的电商平台。我们致力于为用户带来便捷的购物体验，提供丰富多样的商品选择。',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              // 联系方式
              _buildContactItem(
                icon: Icons.email_outlined,
                title: '联系邮箱',
                content: 'support@meituan.com',
              ),
              SizedBox(height: 16.h),
              _buildContactItem(
                icon: Icons.phone_outlined,
                title: '客服电话',
                content: '400-123-4567',
              ),
              SizedBox(height: 16.h),
              _buildContactItem(
                icon: Icons.location_on_outlined,
                title: '公司地址',
                content: '北京市朝阳区望京东路6号',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24.r,
            color: AppColors.primary,
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 