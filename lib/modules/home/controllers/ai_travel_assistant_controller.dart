import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../models/agent_model.dart';

class AiTravelAssistantController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isExecuting = false.obs;
  final RxBool isAiResponding = false.obs;
  
  final ApiService _apiService = Get.find<ApiService>();
  final Rx<ScrollController> scrollController = ScrollController().obs;

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
    scrollController.value.dispose();
    super.onClose();
  }

  Future<void> handleUserInput(String text) async {
    if (text.isEmpty || isAiResponding.value) return;
    
    // 添加用户消息
    addUserMessage(text);
    
    // 清空输入框
    textController.clear();
    
    // 滚动到底部
    _scrollToBottom();
    
    // 设置AI正在响应
    isAiResponding.value = true;
    isExecuting.value = true;
    
    try {
      // 添加"正在思考中..."的消息
      addBotMessage('正在思考中...');
      
      // 构建对话历史
      final chatHistory = <Map<String, String>>[];
      
      // 添加系统提示词
      chatHistory.add({
        'role': 'system',
        'content': '你是一个专业的出行规划助手，可以帮助用户规划旅行、提供交通建议、推荐景点和住宿等。请提供详细、有用的建议，包括时间、价格和实用信息。'
      });
      
      // 添加对话历史，但过滤掉"正在思考中..."的消息
      final filteredMessages = messages
          .where((msg) => msg['content'] != '正在思考中...')
          .toList();

      // 遍历消息，构建对话历史
      for (int i = 0; i < filteredMessages.length; i++) {
        final msg = filteredMessages[i];
        
        if (msg['isUser'] as bool) {
          chatHistory.add({
            'role': 'user',
            'content': msg['content'].toString()
          });
        } else {
          // AI消息
          chatHistory.add({
            'role': 'assistant',
            'content': msg['content'].toString()
          });
        }
      }

      // 打印最终的对话历史，便于调试
      debugPrint('发送对话历史: $chatHistory');
      
      final response = await _apiService.chatWithAI(
        agentId: 'travel_assistant',
        messages: chatHistory,
        agentName: '出行规划助手',
        agentPrompt: '你是一个专业的出行规划助手，可以帮助用户规划旅行、提供交通建议、推荐景点和住宿等。请提供详细、有用的建议，包括时间、价格和实用信息。',
      );

      // 移除"正在思考中..."的消息
      messages.removeLast();

      if (response['error'] == true) {
        addBotMessage('抱歉，我暂时无法回答您的问题。请稍后再试。');
      } else {
        final aiResponse = response['choices'][0]['message']['content'] as String;
        addBotMessage(aiResponse);
      }
    } catch (e) {
      // 移除"正在思考中..."的消息（如果存在）
      if (messages.isNotEmpty && messages.last['content'] == '正在思考中...') {
        messages.removeLast();
      }
      addBotMessage('抱歉，出现了一些问题，无法完成您的请求。错误信息: $e');
      debugPrint('AI对话错误: $e');
    } finally {
      isAiResponding.value = false;
      isExecuting.value = false;
      
      // 再次滚动到底部，确保看到最新消息
      _scrollToBottom();
    }
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
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.value.hasClients) {
        scrollController.value.animateTo(
          scrollController.value.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void startVoiceInput() {
    // 暂未实现语音输入功能
    Get.snackbar('提示', '语音输入功能开发中，敬请期待！');
  }
  
  void stopExecution() {
    isAiResponding.value = false;
    isExecuting.value = false;
    Get.snackbar('提示', '已停止执行');
  }
} 