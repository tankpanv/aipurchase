import 'package:get/get.dart';

class MainController extends GetxController {
  final _currentIndex = 0.obs;
  
  int get currentIndex => _currentIndex.value;
  
  void changePage(int index) {
    _currentIndex.value = index;
  }
} 