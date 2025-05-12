import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiTravelAssistantController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isExecuting = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 添加欢迎消息
    addBotMessage('欢迎使用出行规划助手！请告诉我您的出行需求，例如：\n'
        '1. 帮我规划北京三日游行程\n'
        '2. 从上海到杭州的交通方式有哪些\n'
        '3. 推荐几个适合春季旅游的城市');
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  void handleUserInput(String text) {
    if (text.isEmpty) return;
    
    // 添加用户消息
    addUserMessage(text);
    
    // 清空输入框
    textController.clear();
    
    // 模拟处理请求
    isExecuting.value = true;
    
    // 模拟延迟响应
    Future.delayed(const Duration(seconds: 1), () {
      final response = _generateResponse(text);
      addBotMessage(response);
      isExecuting.value = false;
    });
  }
  
  void addUserMessage(String content) {
    messages.add({
      'isUser': true,
      'content': content,
      'time': DateTime.now(),
    });
  }
  
  void addBotMessage(String content) {
    messages.add({
      'isUser': false,
      'content': content,
      'time': DateTime.now(),
    });
  }
  
  String _generateResponse(String userInput) {
    // 简单的模拟响应逻辑
    if (userInput.contains('北京') && userInput.contains('三日游')) {
      return '北京三日游行程推荐：\n'
          '第一天：天安门广场 → 故宫 → 景山公园 → 北海公园\n'
          '第二天：八达岭长城 → 奥林匹克公园\n'
          '第三天：颐和园 → 圆明园 → 798艺术区';
    } else if (userInput.contains('上海') && userInput.contains('杭州')) {
      return '从上海到杭州的交通方式：\n'
          '1. 高铁：上海虹桥站到杭州东站，约1小时，票价约80元\n'
          '2. 汽车：上海长途客运总站到杭州汽车东站，约2.5小时，票价约70元\n'
          '3. 自驾：沪杭高速，约2小时，过路费约100元';
    } else if (userInput.contains('春季') && userInput.contains('旅游')) {
      return '春季旅游推荐城市：\n'
          '1. 苏州：园林赏花，太湖风光\n'
          '2. 武汉：樱花盛开的季节\n'
          '3. 杭州：西湖春景，龙井茶园\n'
          '4. 厦门：鼓浪屿，温暖宜人的气候';
    } else {
      return '您好，我是出行规划助手。我可以帮您规划行程，推荐景点，查询交通方式等。请具体描述您的出行需求，我会为您提供更精准的建议。';
    }
  }
  
  void startVoiceInput() {
    // 暂未实现语音输入功能
    Get.snackbar('提示', '语音输入功能开发中，敬请期待！');
  }
  
  void stopExecution() {
    isExecuting.value = false;
    Get.snackbar('提示', '已停止执行');
  }
} 