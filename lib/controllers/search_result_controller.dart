import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class SearchResultController extends GetxController {
  final _apiService = Get.find<ApiService>();
  
  final products = <ProductSimple>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;

  // 搜索参数
  String? keyword;
  String? tag;
  double? priceMin;
  double? priceMax;
  String? sort;
  String? order;

  @override
  void onInit() {
    super.onInit();
    // 获取路由参数
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      keyword = args['keyword'] as String?;
      tag = args['tag'] as String?;
      priceMin = args['price_min'] as double?;
      priceMax = args['price_max'] as double?;
      sort = args['sort'] as String?;
      order = args['order'] as String?;
    }
    // 初始加载数据
    searchProducts(refresh: true);
  }

  // 刷新数据
  Future<void> refreshData() async {
    await searchProducts(refresh: true);
  }

  // 搜索商品
  Future<void> searchProducts({bool refresh = false}) async {
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
        '/api/app/products/search',
        queryParameters: {
          'page': currentPage.value,
          'per_page': 10,
          if (keyword?.isNotEmpty == true) 'keyword': keyword,
          if (tag?.isNotEmpty == true) 'tag': tag,
          if (priceMin != null) 'price_min': priceMin,
          if (priceMax != null) 'price_max': priceMax,
          if (sort?.isNotEmpty == true) 'sort': sort,
          if (order?.isNotEmpty == true) 'order': order,
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
        errorMessage.value = data['message'] ?? '搜索失败';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '搜索失败：$e';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // 更新排序方式
  void updateSort(String sortField, {bool isAsc = true}) {
    sort = sortField;
    order = isAsc ? 'asc' : 'desc';
    searchProducts(refresh: true);
  }

  // 更新价格范围
  void updatePriceRange(double? min, double? max) {
    priceMin = min;
    priceMax = max;
    searchProducts(refresh: true);
  }

  // 更新搜索关键词
  void updateKeyword(String value) {
    keyword = value;
  }
} 