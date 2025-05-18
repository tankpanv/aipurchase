import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/command_executor.dart';

class AiAssistantController extends GetxController {
  final CommandExecutor _executor = Get.find<CommandExecutor>();
  final TextEditingController textController = TextEditingController();
  
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isExecuting = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    addMessage('AI助手', '您好！我是您的生活服务助手，请问有什么可以帮您的？', false);
    
  }
  
  void addMessage(String sender, String content, bool isUser) {
    messages.add({
      'sender': sender,
      'content': content,
      'isUser': isUser,
      'time': DateTime.now(),
    });
  }
  
  Future<void> handleUserInput(String input) async {
    if (input.trim().isEmpty) return;
    
    addMessage('用户', input, true);
    textController.clear();
    
    isExecuting.value = true;
    try {
      final command = input.split(' ')[0].toLowerCase();
      _executor.executeCommand(command);
      addMessage('AI助手', '已执行命令：$command', false);
    } catch (e) {
      addMessage('AI助手', '抱歉，处理您的请求时出现了错误', false);
    } finally {
      isExecuting.value = false;
    }
  }
  
  Future<void> startVoiceInput() async {
    // TODO: 实现语音输入
    addMessage('系统', '语音输入功能即将推出', false);
  }
  
  void stopExecution() {
    isExecuting.value = false;
  }
  
  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
} 