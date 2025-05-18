import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../models/agent_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AiTravelAssistantController extends GetxController {
  final TextEditingController textController = TextEditingController();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isExecuting = false.obs;
  final RxBool isAiResponding = false.obs;
  
  final ApiService _apiService = Get.find<ApiService>();
  final Rx<ScrollController> scrollController = ScrollController().obs;
  
  // 智能体相关
  final Rx<Agent?> selectedAgent = Rx<Agent?>(null);
  final RxList<Agent> availableAgents = <Agent>[].obs;
  
  // 流式响应相关
  final RxString currentStreamResponse = ''.obs;
  final RxBool isStreamResponding = false.obs;
  
  // 是否使用模拟数据（调试时可设为true）
  final bool useMockData = false;

  @override
  void onInit() {
    super.onInit();
    _loadAgents();
    
    // 默认选择出行规划智能体
    selectedAgent.value = Agent(
      id: 'travel_assistant',
      name: '出行规划',
      description: '帮助用户规划旅行、提供交通建议、推荐景点和住宿等',
      prompt: '你是一个专业的出行规划助手，可以帮助用户规划旅行、提供交通建议、推荐景点和住宿等。请提供详细、有用的建议，包括时间、价格和实用信息。',
      iconId: 'map',
      tags: ['旅行', '交通', '住宿'],
    );
    
    // 添加欢迎消息
    addBotMessage('欢迎使用出行规划助手！请告诉我您的出行需求，例如：\n'
        '1. 帮我规划北京三日游行程\n'
        '2. 从上海到杭州的交通方式有哪些\n'
        '3. 推荐几个适合春季旅游的城市');
  }
  
  void _loadAgents() {
    availableAgents.value = [
      Agent(
        id: 'travel_assistant',
        name: '出行规划',
        description: '帮助用户规划旅行、提供交通建议、推荐景点和住宿等',
        prompt: '你是一个专业的出行规划助手，可以帮助用户规划旅行、提供交通建议、推荐景点和住宿等。请提供详细、有用的建议，包括时间、价格和实用信息。',
        iconId: 'map',
        tags: ['旅行', '交通', '住宿'],
      ),
      Agent(
        id: 'web_search',
        name: '网络搜索',
        description: '帮助用户查找互联网上的信息，提供准确的搜索结果',
        prompt: '你是一个专业的网络搜索助手，可以帮助用户查找互联网上的信息。请提供准确、全面的搜索结果，并尽可能给出信息来源。',
        iconId: 'search',
        tags: ['搜索', '资讯', '信息'],
      ),
    ];
  }
  
  void selectAgent(Agent agent) {
    selectedAgent.value = agent;
    // 清空对话
    messages.clear();
    
    // 添加欢迎消息
    if (agent.id == 'travel_assistant') {
      addBotMessage('欢迎使用出行规划助手！请告诉我您的出行需求，例如：\n'
          '1. 帮我规划北京三日游行程\n'
          '2. 从上海到杭州的交通方式有哪些\n'
          '3. 推荐几个适合春季旅游的城市');
    } else if (agent.id == 'web_search') {
      addBotMessage('欢迎使用网络搜索助手！请告诉我您想搜索的内容，例如：\n'
          '1. 最近的热门电影\n'
          '2. 国内旅游景点排名\n'
          '3. 健康饮食的建议');
    } else {
      addBotMessage('您好！我是您的${agent.name}助手，${agent.description}');
    }
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
      
      // 添加系统提示词，使用当前选择的智能体的prompt
      final agent = selectedAgent.value;
      final prompt = agent?.prompt ?? '你是一个专业的出行规划助手，可以帮助用户规划旅行、提供交通建议、推荐景点和住宿等。请提供详细、有用的建议，包括时间、价格和实用信息。';
      
      chatHistory.add({
        'role': 'system',
        'content': prompt
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
      
      // 移除"正在思考中..."的消息
      messages.removeLast();
      
      // 添加一个流式响应的临时消息
      final int messageIndex = messages.length;
      addBotMessage('');
      
      // 重置当前流式响应
      currentStreamResponse.value = '';
      isStreamResponding.value = true;
      
      // 发起流式请求
     
        // 使用真实API
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id')?.toString() ?? 'unknown_user';
        print('agentId: ${agent?.id}');
        await _apiService.sendWorkflowRequest(
          agentId: agent?.id ?? '',
          agentName: agent?.name ?? '',
          agentPrompt: agent?.prompt ?? '',
          prompt: text,
          userId: userId,
          chatHistory: chatHistory,
          conversationId: 'conv_${DateTime.now().millisecondsSinceEpoch}',
          onEvent: (event, data) {
            _handleStreamEvent(event, data, messageIndex);
          },
          onError: (error) {
            debugPrint('流式请求错误: $error');
            // 更新最后一条消息为错误信息
            if (messages.length > messageIndex) {
              messages[messageIndex] = {
                'isUser': false,
                'content': '抱歉，出现了一些问题: $error',
                'time': DateTime.now(),
              };
            }
            isStreamResponding.value = false;
            isAiResponding.value = false;
            isExecuting.value = false;
          },
          onDone: () {
            debugPrint('流式请求完成');
            isStreamResponding.value = false;
            isAiResponding.value = false;
            isExecuting.value = false;
            
            // 再次滚动到底部，确保看到最新消息
            _scrollToBottom();
          },
        );
    
      
    } catch (e) {
      // 出现异常，添加错误消息
      debugPrint('AI对话错误: $e');
      addBotMessage('抱歉，出现了一些问题，无法完成您的请求。错误信息: $e');
      isAiResponding.value = false;
      isExecuting.value = false;
      isStreamResponding.value = false;
    }
  }
  
  void _handleStreamEvent(String event, Map<String, dynamic> data, int messageIndex) {
    if (event == 'text_chunk') {
      // 处理文本块
      final String text = data['text'] ?? '';
      
      // 添加到当前流式响应中
      currentStreamResponse.value += text;
      
      // 更新消息
      if (messages.length > messageIndex) {
        messages[messageIndex] = {
          'isUser': false,
          'content': currentStreamResponse.value,
          'time': DateTime.now(),
        };
      }
      
      // 滚动到底部
      _scrollToBottom();
    } else if (event == 'workflow_finished') {
      // 工作流完成
      debugPrint('工作流完成: ${data['outputs']}');
      
      // 如果有输出结果，可以在这里处理
      if (data['outputs'] != null && data['outputs']['summary'] != null) {
        final String summary = data['outputs']['summary'];
        debugPrint('工作流输出摘要: $summary');
      }
      
      // 确保立即更新UI状态
      isStreamResponding.value = false;
      isAiResponding.value = false;
      isExecuting.value = false;
      
      // 强制更新最后一条消息，确保刷新UI
      if (messages.isNotEmpty && !messages.last['isUser']) {
        final lastMessage = messages.last;
        messages[messages.length - 1] = {
          'isUser': lastMessage['isUser'],
          'content': lastMessage['content'],
          'time': DateTime.now(),
        };
      }
      
      // 添加延迟处理，确保UI状态被完全更新
      Future.delayed(const Duration(milliseconds: 500), () {
        // 再次确认状态已更新
        isStreamResponding.value = false;
        isAiResponding.value = false;
        isExecuting.value = false;
        
        // 强制刷新messages列表
        if (messages.isNotEmpty) {
          final temp = messages.toList();
          messages.clear();
          messages.addAll(temp);
        }
        
        // 滚动到底部
        _scrollToBottom();
      });
      
      // 滚动到底部
      _scrollToBottom();
    } else if (event == 'node_finished') {
      // 节点完成
      debugPrint('节点完成: ${data['node_type']} - ${data['title']}');
      
      // 如果有特定节点的输出，可以在这里处理
      if (data['outputs'] != null) {
        debugPrint('节点输出: ${data['outputs']}');
      }
    } else if (event == 'workflow_started') {
      // 工作流开始
      debugPrint('工作流开始: ${data['id']}');
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
    isStreamResponding.value = false;
    
    // 如果正在显示"正在思考中..."，先移除该消息
    if (messages.isNotEmpty && messages.last['content'] == '正在思考中...') {
      messages.removeLast();
    }
    
    // 如果当前有流式响应但被中断，将当前的流式响应内容保存为最终消息
    if (messages.isNotEmpty && currentStreamResponse.value.isNotEmpty) {
      // 确保最后一条消息是流式响应
      if (!messages.last['isUser'] as bool) {
        messages.last['content'] = currentStreamResponse.value + '\n\n[用户中断了对话]';
        messages.last['time'] = DateTime.now();
      }
    }
    
    Get.snackbar('提示', '已停止执行');
  }
} 