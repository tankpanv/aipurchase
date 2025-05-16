import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../home/views/home_view.dart';
import '../home/views/cart_view.dart';
import '../home/views/profile_view.dart';
import '../home/views/ai_assistant_view_travel.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_pages.dart';
import '../../modules/home/bindings/ai_travel_binding.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _currentIndex = 0;
  late final List<Widget> pages;
  
  @override
  void initState() {
    super.initState();
    // 初始化出行助手控制器
    AiTravelBinding().dependencies();
    
    pages = [
    HomeView(),
    const CartView(),
      const AiAssistantTravelView(),
    const ProfileView(),
  ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: '购物车',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: '出行',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
} 