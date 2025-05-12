import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保 AuthController 已注册
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 用户信息卡片
              _buildUserInfoCard(),
              SizedBox(height: 12.h),
              
              // 订单管理
              _buildOrderSection(),
              SizedBox(height: 12.h),
              
              // 工具菜单
              _buildToolsSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  // 用户信息卡片
  Widget _buildUserInfoCard() {
    return GestureDetector(
      onTap: () {
        if (controller.isLoggedIn.value) {
          Get.toNamed(Routes.USER_INFO);
        } else {
          Get.toNamed(Routes.LOGIN);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.r),
        color: Colors.white,
        child: Row(
          children: [
            // 头像
            Obx(() => controller.isLoggedIn.value && controller.currentUser.value?.avatar != null
              ? CircleAvatar(
                  radius: 40.r,
                  backgroundImage: NetworkImage(
                    'https://aipurchase_server.huanfangsk.com/${controller.currentUser.value!.avatar!}',
                  ),
                )
              : CircleAvatar(
                  radius: 40.r,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 40.r,
                    color: AppColors.primary,
                  ),
                )
            ),
            SizedBox(width: 16.w),
            
            // 用户信息
            Expanded(
              child: Obx(() => controller.isLoggedIn.value
                // 已登录状态
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.currentUser.value?.name ?? '用户',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        controller.currentUser.value?.phone ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                // 未登录状态
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '点击登录',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '登录后享受更多权益',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  // 订单管理
  Widget _buildOrderSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (controller.isLoggedIn.value) {
                Get.toNamed(Routes.ORDERS);
              } else {
                Get.toNamed(Routes.LOGIN);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '我的订单',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '查看全部订单',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16.r,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOrderItem(
                Icons.payment,
                '待付款',
                onTap: () {
                  if (controller.isLoggedIn.value) {
                    Get.toNamed(Routes.ORDERS, arguments: {'status': 'pending_payment'});
                  } else {
                    Get.toNamed(Routes.LOGIN);
                  }
                },
              ),
              _buildOrderItem(
                Icons.local_shipping_outlined,
                '待收货',
                onTap: () {
                  if (controller.isLoggedIn.value) {
                    Get.toNamed(Routes.ORDERS, arguments: {'status': 'pending_receipt'});
                  } else {
                    Get.toNamed(Routes.LOGIN);
                  }
                },
              ),
              _buildOrderItem(
                Icons.star_border,
                '待评价',
                onTap: () {
                  if (controller.isLoggedIn.value) {
                    Get.toNamed(Routes.ORDERS, arguments: {'status': 'pending_review'});
                  } else {
                    Get.toNamed(Routes.LOGIN);
                  }
                },
              ),
              _buildOrderItem(
                Icons.assignment_return_outlined,
                '退款/售后',
                onTap: () {
                  if (controller.isLoggedIn.value) {
                    Get.toNamed(Routes.ORDERS, arguments: {'status': 'refunding'});
                  } else {
                    Get.toNamed(Routes.LOGIN);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 订单项
  Widget _buildOrderItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: 28.r,
            color: AppColors.textPrimary,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  // 工具菜单
  Widget _buildToolsSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      color: Colors.white,
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildToolItem(Icons.location_on_outlined, '收货地址', onTap: () {
            if (controller.isLoggedIn.value) {
              Get.toNamed(Routes.ADDRESS_LIST);
            } else {
              Get.toNamed(Routes.LOGIN);
            }
          }),
          _buildToolItem(
            Icons.settings_outlined, 
            '设置',
            onTap: () => Get.toNamed(Routes.SETTINGS),
          ),
          _buildToolItem(
            Icons.info_outline, 
            '关于我们',
            onTap: () => Get.toNamed(Routes.ABOUT),
          ),
        
          // 退出登录/更多服务按钮
          Obx(() => controller.isLoggedIn.value 
            ? _buildToolItem(Icons.exit_to_app, '退出登录', onTap: () => _showLogoutDialog())
            : Container() 
          ),
        ],
      ),
    );
  }
  
  // 显示退出登录对话框
  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('确认退出登录？'),
        content: const Text('您确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('确认', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // 工具项
  Widget _buildToolItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28.r,
            color: AppColors.textPrimary,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 