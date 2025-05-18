import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../routes/app_pages.dart';
import '../utils/storage.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final ImagePicker _imagePicker = ImagePicker();
  
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  
  // 文本控制器
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  
  // 标签和兴趣爱好
  final RxList<String> tags = <String>[].obs;
  final RxList<String> interests = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    debugPrint('AuthController 初始化');
    checkLoginStatus();
  }
  
  @override
  void onClose() {
    userNameController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    bioController.dispose();
    super.onClose();
  }
  
  // 检查登录状态
  Future<void> checkLoginStatus() async {
    debugPrint('检查登录状态');
    isLoading.value = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      debugPrint('当前token: ${token != null ? '存在' : '不存在'}');
      
      if (token != null) {
        isLoggedIn.value = true;
        await fetchUserInfo();
      }
    } catch (e) {
      debugPrint('检查登录状态异常: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // 注册
  Future<void> register() async {
    if (userNameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        phoneController.text.isEmpty) {
      Get.snackbar('错误', '请填写所有必填字段');
      return;
    }
    
    debugPrint('开始注册: ${userNameController.text}');
    isLoading.value = true;
    EasyLoading.show(status: '注册中...');
    
    try {
      final response = await _apiService.register(
        userName: userNameController.text,
        password: passwordController.text,
        name: nameController.text,
        phone: phoneController.text,
      );
      
      debugPrint('注册结果: ${response.isSuccess} ${response.message}');
      
      if (response.isSuccess) {
        Get.snackbar('成功', response.message ?? '注册成功');
        Get.offAllNamed(Routes.LOGIN);
      } else {
        Get.snackbar('错误', response.message ?? '注册失败，请重试');
      }
    } catch (e) {
      debugPrint('注册异常: $e');
      Get.snackbar('错误', '注册过程中发生异常');
    } finally {
      isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  // 登录
  Future<void> login() async {
    if (userNameController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('错误', '请输入用户名和密码');
      return;
    }
    
    debugPrint('开始登录: ${userNameController.text}');
    isLoading.value = true;
    EasyLoading.show(status: '登录中...');
    
    try {
      final response = await _apiService.login(
        userName: userNameController.text,
        password: passwordController.text,
      );
      
      debugPrint('登录结果: ${response.isSuccess} ${response.message}');
      
      if (response.isSuccess) {
        isLoggedIn.value = true;
        await fetchUserInfo();
        debugPrint('登录成功，跳转到首页');
        Get.offAllNamed(Routes.HOME);
      } else {
        debugPrint('登录失败: ${response.message}');
        Get.snackbar('错误', response.message);
      }
    } catch (e) {
      debugPrint('登录异常: $e');
      Get.snackbar('错误', '登录过程中发生异常');
    } finally {
      isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  // 获取用户信息
  Future<void> fetchUserInfo() async {
    debugPrint('开始获取用户信息');
    isLoading.value = true;
    
    try {
      final response = await _apiService.getUserInfo();
      
      debugPrint('获取用户信息结果: ${response.isSuccess}');
      
      if (response.isSuccess && response.data is User) {
        final oldAvatar = currentUser.value?.avatar;
        currentUser.value = response.data as User;
        debugPrint('获取用户信息成功: ${currentUser.value?.name}');
        debugPrint('头像信息: 旧头像=$oldAvatar, 新头像=${currentUser.value?.avatar}');
        
        // 详细记录头像URL格式
        if (currentUser.value?.avatar != null) {
          final avatarUrl = currentUser.value!.avatar!;
          debugPrint('头像URL详情分析:');
          debugPrint('- URL: $avatarUrl');
          debugPrint('- 是否完整URL: ${avatarUrl.startsWith('http')}');
          if (avatarUrl.startsWith('http')) {
            debugPrint('- 域名: ${Uri.parse(avatarUrl).host}');
            debugPrint('- 路径: ${Uri.parse(avatarUrl).path}');
          } else {
            debugPrint('- 是相对路径');
          }
        }
        
        // 填充文本控制器
        nameController.text = currentUser.value?.name ?? '';
        phoneController.text = currentUser.value?.phone ?? '';
        emailController.text = currentUser.value?.email ?? '';
        addressController.text = currentUser.value?.address ?? '';
        bioController.text = currentUser.value?.bio ?? '';
        
        // 更新标签和兴趣爱好列表
        tags.clear();
        if (currentUser.value?.tags != null) {
          tags.addAll(currentUser.value!.tags!);
        }
        
        interests.clear();
        if (currentUser.value?.interests != null) {
          interests.addAll(currentUser.value!.interests!);
        }
      } else {
        debugPrint('获取用户信息失败: ${response.message}');
        Get.snackbar('错误', response.message ?? '获取用户信息失败');
      }
    } catch (e) {
      debugPrint('获取用户信息异常: $e');
      Get.snackbar('错误', '获取用户信息过程中发生异常');
    } finally {
      isLoading.value = false;
    }
  }
  
  // 更新用户信息
  Future<void> updateUserInfo() async {
    // 打印原始用户信息
    debugPrint('准备更新用户信息，原始用户信息如下:');
    debugPrint('ID: ${currentUser.value?.id}');
    debugPrint('用户名: ${currentUser.value?.userName}');
    debugPrint('姓名: ${currentUser.value?.name}');
    debugPrint('手机: ${currentUser.value?.phone}');
    debugPrint('邮箱: ${currentUser.value?.email}');
    debugPrint('地址: ${currentUser.value?.address}');
    debugPrint('头像: ${currentUser.value?.avatar}');
    debugPrint('个人简介: ${currentUser.value?.bio}');
    debugPrint('标签: ${currentUser.value?.tags}');
    debugPrint('兴趣爱好: ${currentUser.value?.interests}');
    debugPrint('创建时间: ${currentUser.value?.createdAt}');
    debugPrint('--------------------');
    debugPrint('待更新的内容:');
    debugPrint('姓名: ${nameController.text}');
    debugPrint('手机: ${phoneController.text}');
    debugPrint('邮箱: ${emailController.text}');
    debugPrint('地址: ${addressController.text}');
    debugPrint('个人简介: ${bioController.text}');
    debugPrint('标签: $tags');
    debugPrint('兴趣爱好: $interests');
    
    isLoading.value = true;
    EasyLoading.show(status: '更新中...');
    
    final response = await _apiService.updateUserInfo(
      name: nameController.text,
      phone: phoneController.text,
      email: emailController.text,
      address: addressController.text,
      bio: bioController.text,
      tags: tags,
      interests: interests,
    );
    
    isLoading.value = false;
    EasyLoading.dismiss();
    
    if (response.isSuccess) {
      Get.snackbar('成功', response.message ?? '用户信息更新成功');
      await fetchUserInfo();
    } else {
      Get.snackbar('错误', response.message ?? '更新用户信息失败');
    }
  }
  
  // 更新密码
  Future<void> updatePassword() async {
    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Get.snackbar('错误', '请填写所有密码字段');
      return;
    }
    
    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar('错误', '新密码和确认密码不匹配');
      return;
    }
    
    isLoading.value = true;
    EasyLoading.show(status: '更新密码中...');
    
    final response = await _apiService.updatePassword(
      currentPassword: currentPasswordController.text,
      newPassword: newPasswordController.text,
    );
    
    isLoading.value = false;
    EasyLoading.dismiss();
    
    if (response.isSuccess) {
      Get.snackbar('成功', response.message ?? '密码更新成功');
      // 清空密码字段
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } else {
      Get.snackbar('错误', response.message ?? '密码更新失败');
    }
  }
  
  // 退出登录
  Future<void> logout() async {
    debugPrint('退出登录');
    await _apiService.logout();
    currentUser.value = null;
    isLoggedIn.value = false;
    Get.offAllNamed(Routes.LOGIN);
  }
  
  // 重置表单
  void resetForms() {
    debugPrint('重置表单');
    userNameController.clear();
    passwordController.clear();
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    bioController.clear();
  }
  
  // 选择图片
  Future<File?> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('选择图片异常: $e');
      Get.snackbar('提示', '选择图片失败');
      return null;
    }
  }
  
  // 上传头像
  Future<void> uploadAvatar(ImageSource source) async {
    if (!isLoggedIn.value) {
      Get.snackbar('提示', '请先登录');
      return;
    }
    
    final image = await pickImage(source);
    if (image == null) return;
    
    isLoading.value = true;
    EasyLoading.show(status: '上传中...');
    
    try {
      debugPrint('开始上传头像...');
      final response = await _apiService.uploadImages([image.path]);
      
      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        // 获取上传成功的图片URL - 直接使用服务器返回的完整URL
        String imageUrl = response.data![0];
        debugPrint('图片上传成功，服务器返回的URL: $imageUrl');
        
        // 更新用户头像 - 直接使用原始URL，不做任何处理
        final updateResponse = await _apiService.updateUserAvatar(imageUrl);
        
        if (updateResponse.isSuccess) {
          Get.snackbar('成功', '头像更新成功');
          // 临时更新头像显示，不等待fetchUserInfo
          if (currentUser.value != null) {
            // 保存原始值以便调试
            String? oldAvatar = currentUser.value!.avatar;
            
            // 更新头像URL - 使用原始URL
            currentUser.value!.avatar = imageUrl;
            debugPrint('头像已更新: 旧=$oldAvatar, 新=${currentUser.value!.avatar}');
            debugPrint('注意: 服务器接收的字段名为avatar_url，但本地User模型中仍使用avatar字段');
            
            // 触发Obx刷新
            currentUser.refresh();
          }
          
          // 从服务器刷新用户信息
          await fetchUserInfo();
          debugPrint('刷新后的头像URL: ${currentUser.value?.avatar}');
        } else {
          Get.snackbar('提示', updateResponse.message ?? '头像信息更新失败');
          debugPrint('头像信息更新失败: ${updateResponse.message}');
        }
      } else {
        Get.snackbar('提示', response.message ?? '图片上传失败');
        debugPrint('图片上传失败: ${response.message}');
      }
    } catch (e) {
      debugPrint('上传头像异常: $e');
      Get.snackbar('错误', '上传头像过程中发生异常');
    } finally {
      isLoading.value = false;
      EasyLoading.dismiss();
    }
  }
  
  // 添加新标签
  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag)) {
      tags.add(tag);
    }
  }
  
  // 删除标签
  void removeTag(String tag) {
    tags.remove(tag);
  }
  
  // 添加兴趣爱好
  void addInterest(String interest) {
    if (interest.isNotEmpty && !interests.contains(interest)) {
      interests.add(interest);
    }
  }
  
  // 删除兴趣爱好
  void removeInterest(String interest) {
    interests.remove(interest);
  }
  
  // 打印当前用户token
  Future<void> printUserToken() async {
    debugPrint('正在获取用户token...');
    try {
      final token = await Storage.getToken();
      debugPrint('==================== 用户Token ====================');
      debugPrint('Token: $token');
      debugPrint('Token 是否存在: ${token != null ? '存在' : '不存在'}');
      if (token != null) {
        debugPrint('Token 长度: ${token.length}');
        debugPrint('Token 前20个字符: ${token.length > 20 ? token.substring(0, 20) + '...' : token}');
      }
      debugPrint('==================================================');
      Get.snackbar('Token信息', token != null ? 'Token已打印到控制台' : '未找到Token，请先登录');
    } catch (e) {
      debugPrint('获取Token异常: $e');
      Get.snackbar('错误', '获取Token时发生错误');
    }
  }
} 