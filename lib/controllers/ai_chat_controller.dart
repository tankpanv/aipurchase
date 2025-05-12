import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/command_executor.dart';
import '../services/api_service.dart';
import '../models/agent_model.dart';

class AIChatController extends GetxController {
  final CommandExecutor _executor = Get.find<CommandExecutor>();
  final ApiService _apiService = Get.find<ApiService>();
  final TextEditingController textController = TextEditingController();
  final Rx<ScrollController?> scrollController = Rx<ScrollController?>(null);

  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isExecuting = false.obs;
  final RxBool isAiResponding = false.obs;
  
  // 智能体相关
  final Rx<Agent?> selectedAgent = Rx<Agent?>(null);
  final RxList<Agent> availableAgents = <Agent>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initScrollController();
    _loadAgents();
    
    // 默认选择购物推荐智能体
    selectedAgent.value = Agent.getAgentById('shopping');
    
    addWelcomeMessage();
  }
  
  void _loadAgents() {
    availableAgents.value = Agent.getAgents();
  }
  
  void selectAgent(Agent agent) {
    selectedAgent.value = agent;
    // 清空对话
    messages.clear();
    addWelcomeMessage();
  }
  
  void addWelcomeMessage() {
    final agent = selectedAgent.value;
    if (agent != null) {
      addMessage(agent.name, '您好！我是您的${agent.name}助手，${agent.description}', false);
      addMessage(agent.name, '有什么我可以帮您的吗？', false);
    } else {
      addMessage('AI助手', '您好！我是您的智能助手，请问有什么可以帮您的？', false);
      addMessage('AI助手', '请先选择一个智能体开始对话。', false);
    }
  }

  void _initScrollController() {
    scrollController.value?.dispose();
    scrollController.value = ScrollController();
  }

  void addMessage(String sender, String content, bool isUser) {
    messages.add({
      'sender': sender,
      'content': content,
      'isUser': isUser,
      'time': DateTime.now(),
    });

    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      final controller = scrollController.value;
      if (controller != null && controller.hasClients) {
        try {
          controller.animateTo(
            controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          debugPrint('滚动错误: $e');
        }
      }
    });
  }

  Future<void> handleUserInput(String input) async {
    if (input.trim().isEmpty) return;

    // 检查是否选择了智能体
    if (selectedAgent.value == null) {
      addMessage('用户', input, true);
      addMessage('AI助手', '请先选择一个智能体开始对话。', false);
      textController.clear();
      return;
    }

    final agent = selectedAgent.value!;
    
    // 记录原始用户输入
    addMessage('用户', input, true);
    textController.clear();

    isExecuting.value = true;
    try {
      // 如果不是命令，尝试与AI对话
      try {
        isAiResponding.value = true;
        addMessage(agent.name, '正在思考中...', false);

        // 构建对话历史
        final chatHistory = <Map<String, String>>[];
        
        // 添加当前智能体的系统提示词
        chatHistory.add({
          'role': 'system',
          'content': agent.prompt
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
          messages: chatHistory,
          agentName: agent.name,
          agentPrompt: agent.prompt,
        );

        // 移除"正在思考中..."的消息
        messages.removeLast();

        if (response['error'] == true) {
          addMessage(
              agent.name,
              '抱歉，我暂时无法回答您的问题。请稍后再试。',
              false);
        } else {
          final aiResponse =
              response['choices'][0]['message']['content'] as String;
          addMessage(agent.name, aiResponse, false);
        }
      } finally {
        isAiResponding.value = false;
      }
    } catch (e) {
      addMessage(agent.name, '抱歉，处理您的请求时出现了错误：$e', false);
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
    isAiResponding.value = false;
  }

  @override
  void onReady() {
    super.onReady();
    _initScrollController();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.value?.dispose();
    scrollController.value = null;
    super.onClose();
  }
}
