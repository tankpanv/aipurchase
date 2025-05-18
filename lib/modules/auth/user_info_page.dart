import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_pages.dart';

class UserInfoPage extends StatelessWidget {
  final AuthController controller = Get.find<AuthController>();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 打印当前用户信息
    debugPrint('UserInfoPage - 当前用户信息:');
    if (controller.currentUser.value != null) {
      debugPrint('ID: ${controller.currentUser.value?.id}');
      debugPrint('用户名: ${controller.currentUser.value?.userName}');
      debugPrint('姓名: ${controller.currentUser.value?.name}');
      debugPrint('电话: ${controller.currentUser.value?.phone}');
      debugPrint('邮箱: ${controller.currentUser.value?.email}');
      debugPrint('地址: ${controller.currentUser.value?.address}');
      debugPrint('头像: ${controller.currentUser.value?.avatar}');
      debugPrint('个人简介: ${controller.currentUser.value?.bio}');
      debugPrint('标签: ${controller.currentUser.value?.tags}');
      debugPrint('兴趣爱好: ${controller.currentUser.value?.interests}');
      debugPrint('创建时间: ${controller.currentUser.value?.createdAt}');
    } else {
      debugPrint('用户未登录或用户信息为空');
    }
    
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
                        _showImagePickerModal(context);
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
                                    _getAvatarUrl(controller.currentUser.value!.avatar!),
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
                    _buildDivider(),
                    
                    _buildInfoItem(
                      label: '个人简介',
                      controller: controller.bioController,
                      hintText: '介绍一下自己吧',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 10.h),
              
              // 标签
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的标签',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() => Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        ...controller.tags.map((tag) => _buildTag(tag, onDelete: () => controller.removeTag(tag))),
                        _buildAddTagButton(context),
                      ],
                    )),
                  ],
                ),
              ),
              
              SizedBox(height: 10.h),
              
              // 兴趣爱好
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '兴趣爱好',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() => Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        ...controller.interests.map((interest) => _buildTag(
                          interest, 
                          onDelete: () => controller.removeInterest(interest),
                          color: Colors.blue.shade100,
                          textColor: Colors.blue.shade800,
                        )),
                        _buildAddInterestButton(context),
                      ],
                    )),
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
              
              SizedBox(height: 30.h),
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
    int maxLines = 1,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxLines: maxLines,
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
  
  // 显示图片选择对话框
  void _showImagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择头像',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  icon: Icons.camera_alt,
                  title: '拍照',
                  onTap: () {
                    Get.back();
                    controller.uploadAvatar(ImageSource.camera);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  title: '相册',
                  onTap: () {
                    Get.back();
                    controller.uploadAvatar(ImageSource.gallery);
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  '取消',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 构建图片选择选项
  Widget _buildImagePickerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30.r,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 构建标签组件
  Widget _buildTag(String text, {
    required VoidCallback onDelete, 
    Color? color, 
    Color? textColor
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color ?? AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor ?? AppColors.primary,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              size: 16.r,
              color: textColor ?? AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  // 添加标签按钮
  Widget _buildAddTagButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddTagDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16.r,
              color: AppColors.primary,
            ),
            SizedBox(width: 4.w),
            Text(
              '添加标签',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 添加兴趣爱好按钮
  Widget _buildAddInterestButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddInterestDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade300),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16.r,
              color: Colors.blue.shade700,
            ),
            SizedBox(width: 4.w),
            Text(
              '添加兴趣',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 显示添加标签对话框
  void _showAddTagDialog(BuildContext context) {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: _tagController,
          decoration: const InputDecoration(
            hintText: '请输入标签名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_tagController.text.isNotEmpty) {
                controller.addTag(_tagController.text);
                Get.back();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  // 显示添加兴趣爱好对话框
  void _showAddInterestDialog(BuildContext context) {
    _interestController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加兴趣爱好'),
        content: TextField(
          controller: _interestController,
          decoration: const InputDecoration(
            hintText: '请输入兴趣爱好',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_interestController.text.isNotEmpty) {
                controller.addInterest(_interestController.text);
                Get.back();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  String _getAvatarUrl(String avatar) {
    // 直接返回原始URL，不进行任何处理
    debugPrint('UserInfoPage - 使用原始头像URL: $avatar');
    return avatar;
  }
} 