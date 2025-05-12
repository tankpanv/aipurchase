import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductListController extends GetxController {
  final _apiService = Get.find<ApiService>();
  
  final products = <ProductSimple>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;

  String? productType;
  String? keyword;
  String? title;

  @override
  void onInit() {
    super.onInit();
    // 获取路由参数
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      productType = args['productType'] as String?;
      keyword = args['keyword'] as String?;
      title = args['title'] as String?;
    }
    // 初始加载数据
    fetchProducts(refresh: true);
  }

  // 刷新数据
  Future<void> refreshData() async {
    await fetchProducts(refresh: true);
  }

  // 获取商品列表
  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
    }

    if (!hasMore.value || isLoadingMore.value) return;

    try {
      if (refresh) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }
      hasError.value = false;
      errorMessage.value = '';

      final response = await _apiService.get(
        '/api/app/products',
        queryParameters: {
          'page': currentPage.value,
          'per_page': 10,
          if (productType != null) 'product_type': productType,
          if (keyword != null) 'keyword': keyword,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['code'] == 200) {
        final List<dynamic> productList = data['data']['items'] ?? [];
        final List<ProductSimple> newProducts = productList
            .map((item) => ProductSimple.fromJson(item))
            .toList();

        if (refresh) {
          products.value = newProducts;
        } else {
          products.addAll(newProducts);
        }

        totalPages.value = data['data']['pages'] ?? 1;
        hasMore.value = currentPage.value < totalPages.value;
        if (hasMore.value) {
          currentPage.value++;
        }
      } else {
        hasError.value = true;
        errorMessage.value = data['message'] ?? '获取商品列表失败';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '获取商品列表失败：$e';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
} 