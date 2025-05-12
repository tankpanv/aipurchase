import 'package:get/get.dart';
import 'home_controller.dart';
import '../../controllers/main_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 注册 API 服务
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);
    
    // 注册控制器
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
} 