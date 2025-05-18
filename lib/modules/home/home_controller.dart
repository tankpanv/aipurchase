import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../models/product_model.dart';

class HomeController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  
  final RxString searchText = ''.obs;
  
  // 记录加载状态
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // 分页相关
  int currentPage = 1;
  int totalPages = 1;
  
  // 商品列表
  final RxList<ProductSimple> specialOffers = <ProductSimple>[].obs;
  final RxList<ProductSimple> recommendations = <ProductSimple>[].obs;
  
  // 菜单项列表 - 每个菜单项包含对应的productType
  final List<Map<String, dynamic>> menuItems = [
    {'name': '外卖', 'icon': Icons.fastfood, 'productType': 'takeout'},
    {'name': '酒店民宿', 'icon': Icons.hotel, 'productType': 'hotel'},
    {'name': '看病买药', 'icon': Icons.medical_services, 'productType': 'medicine'},
  
    {'name': '电影演出', 'icon': Icons.movie, 'productType': 'ticket'},
    
    {'name': '免费水果', 'icon': Icons.apple, 'productType': 'fresh', 'keyword': '水果'},
  ];
  
  final searchController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();
    fetchSpecialOffers();
    fetchRecommendations();
  }
  
  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
  
  // 刷新所有数据
  Future<void> refreshAllData() async {
    currentPage = 1;
    await Future.wait([
      fetchSpecialOffers(),
      fetchRecommendations(refresh: true),
    ]);
  }
  
  // 获取特价商品
  Future<void> fetchSpecialOffers() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      final response = await _apiService.getProducts(
        isFeatured: true,
        page: 1,
        perPage: 5,
      );
      
      if (response.code == 200) {
        if (response.products.isNotEmpty) {
          specialOffers.value = response.products;
        } else {
          // 如果没有特价商品，获取所有商品并显示前5个
          final allProductsResponse = await _apiService.getProducts(
            page: 1,
            perPage: 5,
          );
          
          if (allProductsResponse.code == 200 && allProductsResponse.products.isNotEmpty) {
            specialOffers.value = allProductsResponse.products;
          } else {
            debugPrint('没有找到特价商品和普通商品');
            specialOffers.clear();
          }
        }
      } else {
        hasError.value = true;
        errorMessage.value = response.message;
        debugPrint('获取特价商品失败: ${response.message}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '加载特价商品失败: $e';
      debugPrint('获取特价商品异常: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // 获取推荐商品
  Future<void> fetchRecommendations({bool refresh = false}) async {
    if (isLoadingMore.value) return;
    
    try {
      if (refresh) {
        isLoading.value = true;
        hasError.value = false;
        currentPage = 1;
      } else {
        if (currentPage > totalPages) return;
        isLoadingMore.value = true;
      }
      
      final response = await _apiService.getProducts(
        page: currentPage,
        perPage: 10,
        sort: 'created_at',
        order: 'desc',
      );
      
      if (response.code == 200) {
        totalPages = response.pages;
        
        if (refresh || currentPage == 1) {
          recommendations.value = response.products;
        } else if (response.products.isNotEmpty) {
          recommendations.addAll(response.products);
        }
        
        // 只有当获取到商品时才增加页码
        if (response.products.isNotEmpty) {
          currentPage++;
        } else {
          debugPrint('当前页没有更多商品');
        }
      } else {
        hasError.value = true;
        errorMessage.value = response.message;
        debugPrint('获取推荐商品失败: ${response.message}');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '加载推荐商品失败: $e';
      debugPrint('获取推荐商品异常: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
  
  // 按照菜单项获取商品
  Future<List<ProductSimple>> fetchProductsByMenuType(Map<String, dynamic> menuItem) async {
    try {
      final productType = menuItem['productType'];
      final keyword = menuItem['keyword'];
      
      final response = await _apiService.getProducts(
        productType: productType,
        keyword: keyword,
        page: 1,
        perPage: 10,
      );
      
      if (response.code == 200) {
        return response.products;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('加载${menuItem['name']}商品失败: $e');
      return [];
    }
  }
  
  void updateSearchText(String text) {
    searchText.value = text;
  }
  
  // 搜索商品
  Future<List<ProductSimple>> searchProducts(String keyword) async {
    if (keyword.isEmpty) return [];
    
    try {
      final response = await _apiService.getProducts(
        keyword: keyword,
        page: 1,
        perPage: 20,
      );
      
      if (response.code == 200) {
        return response.products;
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('搜索商品失败: $e');
      return [];
    }
  }
} 