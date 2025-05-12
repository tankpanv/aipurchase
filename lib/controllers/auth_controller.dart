import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../routes/app_pages.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  
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
        currentUser.value = response.data as User;
        debugPrint('获取用户信息成功: ${currentUser.value?.name}');
        
        // 填充文本控制器
        nameController.text = currentUser.value?.name ?? '';
        phoneController.text = currentUser.value?.phone ?? '';
        emailController.text = currentUser.value?.email ?? '';
        addressController.text = currentUser.value?.address ?? '';
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
    isLoading.value = true;
    EasyLoading.show(status: '更新中...');
    
    final response = await _apiService.updateUserInfo(
      name: nameController.text,
      phone: phoneController.text,
      email: emailController.text,
      address: addressController.text,
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
  }
} 