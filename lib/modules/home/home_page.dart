import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../controllers/main_controller.dart';
import '../../controllers/ai_chat_controller.dart';
import 'home_controller.dart';
import 'views/home_view.dart';
import 'views/ai_chat_view.dart';
import 'views/cart_view.dart';
import 'views/profile_view.dart';
import 'views/ai_assistant_view_travel.dart';
import 'bindings/ai_travel_binding.dart';
import 'controllers/ai_travel_assistant_controller.dart';

class HomePage extends StatelessWidget {
  final HomeController homeController = Get.find<HomeController>();
  final MainController mainController = Get.find<MainController>();
  
  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保 AIChatController 已注册
    if (!Get.isRegistered<AIChatController>()) {
      Get.put(AIChatController());
    }
    
    // 确保出行助手控制器已注册
    if (!Get.isRegistered<AiTravelAssistantController>()) {
      AiTravelBinding().dependencies();
    }
    
    return Scaffold(
      body: Obx(() {
        switch (mainController.currentIndex) {
          case 0:
            return Stack(
              children: [
                HomeView(),
                Positioned(
                  right: 16.w,
                  bottom: 16.h,
                  child: _buildAiFloatingButton(),
                ),
              ],
            );
          case 1:
            return const AIChatView();
          case 2:
            return const AiAssistantTravelView();
          case 3:
            return const CartView();
          case 4:
            return const ProfileView();
          default:
            return HomeView();
        }
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
        currentIndex: mainController.currentIndex,
        onTap: mainController.changePage,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.tabBarBackground,
        selectedItemColor: AppColors.tabBarItemActive,
        unselectedItemColor: AppColors.tabBarItem,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 22.r),
            activeIcon: Icon(Icons.home, size: 22.r),
            label: '推荐',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined, size: 22.r),
            activeIcon: Icon(Icons.smart_toy, size: 22.r),
            label: 'AI助手',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined, size: 22.r),
            activeIcon: Icon(Icons.directions_car, size: 22.r),
            label: '出行',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined, size: 22.r),
            activeIcon: Icon(Icons.shopping_cart, size: 22.r),
            label: '购物车',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 22.r),
            activeIcon: Icon(Icons.person, size: 22.r),
            label: '我的',
          ),
        ],
      )),
    );
  }
  
  // AI悬浮按钮
  Widget _buildAiFloatingButton() {
    return FloatingActionButton(
      onPressed: () => mainController.changePage(1),
      backgroundColor: AppColors.primary,
      tooltip: 'AI助手',
      child: Icon(
        Icons.smart_toy,
        color: Colors.white,
        size: 24.r,
      ),
    );
  }
} 