import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../services/api_service.dart';

class ServiceLocator {
  static void init() {
    // 注册 ApiService
    Get.put(ApiService(), permanent: true);
    
    // 注册 CartController
    Get.put(CartController(), permanent: true);
  }
} 