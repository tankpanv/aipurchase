import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'controllers/main_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/ai_chat_controller.dart';
import 'controllers/cart_controller.dart';
import 'modules/home/home_controller.dart';
import 'services/api_service.dart';
import 'routes/app_pages.dart';
import 'constants/app_colors.dart';
import 'utils/command_executor.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 固定屏幕方向为竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 注册全局服务和控制器
  Get.put(ApiService(), permanent: true);
  Get.put(CommandExecutor(), permanent: true);
  Get.put(MainController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(AIChatController(), permanent: true);
  Get.put(CartController(), permanent: true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // 设计图尺寸
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: '生活服务',
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            fontFamily: 'PingFang SC',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              centerTitle: true,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          builder: EasyLoading.init(),
        );
      },
    );
  }
}
