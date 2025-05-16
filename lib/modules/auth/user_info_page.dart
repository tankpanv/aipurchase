import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_pages.dart';

class UserInfoPage extends StatelessWidget {
  final AuthController controller = Get.find<AuthController>();

  UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '个人信息',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20.r,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: controller.updateUserInfo,
            child: Text(
              '保存',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          child: Column(
            children: [
              // 头像
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                      
                     
                      },
                      child: Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          image: controller.currentUser.value?.avatar != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    'https://sqdftauejboz.sealoshzh.site/${controller.currentUser.value!.avatar!}',
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: controller.currentUser.value?.avatar == null
                            ? Icon(
                                Icons.person,
                                size: 60.r,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '点击修改头像',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 10.h),
              
              // 用户信息表单
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    _buildInfoItem(
                      label: '用户名',
                      value: controller.currentUser.value?.userName ?? '',
                      isEditable: false,
                    ),
                    _buildDivider(),
                    
                    _buildInfoItem(
                      label: '姓名',
                      controller: controller.nameController,
                      hintText: '请输入姓名',
                    ),
                    _buildDivider(),
                    
                    _buildInfoItem(
                      label: '手机号码',
                      controller: controller.phoneController,
                      hintText: '请输入手机号码',
                      keyboardType: TextInputType.phone,
                    ),
                    _buildDivider(),
                    
                    _buildInfoItem(
                      label: '邮箱',
                      controller: controller.emailController,
                      hintText: '请输入邮箱',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildDivider(),
                    
                    _buildInfoItem(
                      label: '地址',
                      controller: controller.addressController,
                      hintText: '请输入地址',
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // 密码修改
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    Get.toNamed(Routes.CHANGE_PASSWORD);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.textPrimary,
                        size: 22.r,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '修改密码',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 16.r,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 30.h),
              
              // 退出登录按钮
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ElevatedButton(
                  onPressed: () {
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
                            child: Text(
                              '确认',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '退出登录',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  

  // 构建信息项
  Widget _buildInfoItem({
    required String label,
    String? value,
    TextEditingController? controller,
    String? hintText,
    bool isEditable = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: isEditable
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 16.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textPrimary,
                    ),
                  )
                : Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 构建分割线
  Widget _buildDivider() {
    return Divider(
      height: 1.h,
      thickness: 1.h,
      color: AppColors.divider,
    );
  }
} 