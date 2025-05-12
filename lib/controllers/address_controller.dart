import 'package:get/get.dart';
import '../models/address.dart';
import '../services/api_service.dart';

class AddressController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final RxList<Address> addresses = <Address>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  // 获取地址列表
  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/api/app/user/addresses');
      
      if (response.data['code'] == 200) {
        final List<dynamic> data = response.data['data'];
        addresses.value = data.map((json) => Address.fromJson(json)).toList();
      } else {
        Get.snackbar('错误', response.data['message'] ?? '获取地址列表失败');
      }
    } catch (e) {
      Get.snackbar('错误', '获取地址列表失败');
    } finally {
      isLoading.value = false;
    }
  }

  // 创建地址
  Future<bool> createAddress(Address address) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(
        '/api/app/user/addresses',
        data: address.toJson(),
      );
      if (response.data['code'] == 200) {
        await fetchAddresses();
        Get.back();
        Get.snackbar('成功', '添加地址成功');
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('错误', '添加地址失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 更新地址
  Future<bool> updateAddress(int id, Address address) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put(
        '/api/app/user/addresses/$id',
        data: address.toJson(),
      );
      if (response.data['code'] == 200) {
        await fetchAddresses();
        Get.back();
        Get.snackbar('成功', '更新地址成功');
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('错误', '更新地址失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 删除地址
  Future<bool> deleteAddress(int id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('/api/app/user/addresses/$id');
      if (response.data['code'] == 200) {
        await fetchAddresses();
        Get.snackbar('成功', '删除地址成功');
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('错误', '删除地址失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 设置默认地址
  Future<bool> setDefaultAddress(int id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/app/user/addresses/$id/default');
      if (response.data['code'] == 200) {
        await fetchAddresses();
        Get.snackbar('成功', '设置默认地址成功');
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('错误', '设置默认地址失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
} 