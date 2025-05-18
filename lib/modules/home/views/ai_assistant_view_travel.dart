import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../constants/app_colors.dart';
import 'dart:convert';
import '../../../widgets/ai_product_card.dart';
import '../../../routes/app_pages.dart';
import 'chat_travel_markdown_view.dart';
import '../../../models/agent_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../controllers/ai_travel_assistant_controller.dart';

// 添加CodeElementBuilder用于更好地渲染代码块
class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    
    if (element.attributes['class'] != null) {
      final regExpLang = RegExp(r'language-(\w+)');
      final match = regExpLang.firstMatch(element.attributes['class']!);
      
      if (match != null && match.groupCount > 0) {
        language = match.group(1)!;
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                language,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          SelectableText(
            element.textContent,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class AiAssistantTravelView extends GetView<AiTravelAssistantController> {
  const AiAssistantTravelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Obx(() => Text(
          controller.selectedAgent.value?.name ?? '出行规划助手',
        )),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.psychology, color: Colors.white),
            onPressed: _showAgentList,
            tooltip: '选择智能体',
          ),
          IconButton(
            icon: Icon(Icons.text_format, color: Colors.white),
            onPressed: () => Get.to(() => const ChatTravelMarkdownView()),
            tooltip: 'Markdown视图',
          ),
        ],
      ),
      body: Column(
        children: [
          // 当前选择的智能体提示
          Obx(() => controller.selectedAgent.value != null
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                  color: AppColors.primary.withOpacity(0.05),
                  child: Row(
                    children: [
                      Icon(
                        _getIconData(controller.selectedAgent.value!.iconId),
                        color: AppColors.primary,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '当前智能体: ${controller.selectedAgent.value!.name}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _showAgentList,
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Text(
                            '切换',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox.shrink()),
              
          // 顶部功能区域
          _buildTopSection(),
          
          // 消息列表区域
          Expanded(
            child: Obx(() => controller.messages.isEmpty 
              ? _buildEmptyState()
              : _buildMessageList()
            ),
          ),
          
          // 底部输入区域
          _buildInputArea(),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller.isExecuting.value) {
          return FloatingActionButton(
            onPressed: controller.stopExecution,
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
  
  void _showAgentList() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (context, scrollController) => _buildAgentListView(scrollController),
      ),
    );
  }
  
  Widget _buildAgentListView(ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              '选择智能体',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Divider(height: 1.h, color: Colors.grey[300]),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: [
                _buildAgentItem(
                  Agent(
                    id: 'travel_assistant',
                    name: '出行规划',
                    description: '帮助用户规划旅行、提供交通建议、推荐景点和住宿等',
                    prompt: '你是一个专业的出行规划助手，可以帮助用户规划旅行、提供交通建议、推荐景点和住宿等。请提供详细、有用的建议，包括时间、价格和实用信息。',
                    iconId: 'map',
                    tags: ['旅行', '交通', '住宿'],
                  ),
                ),
                _buildAgentItem(
                  Agent(
                    id: 'web_search',
                    name: '网络搜索',
                    description: '帮助用户查找互联网上的信息，提供准确的搜索结果',
                    prompt: '你是一个专业的网络搜索助手，可以帮助用户查找互联网上的信息。请提供准确、全面的搜索结果，并尽可能给出信息来源。',
                    iconId: 'search',
                    tags: ['搜索', '资讯', '信息'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAgentItem(Agent agent) {
    return Obx(() {
      final isSelected = controller.selectedAgent.value?.id == agent.id;
      
      return InkWell(
        onTap: () {
          controller.selectAgent(agent);
          Get.back();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getIconData(agent.iconId),
                  color: AppColors.primary,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      agent.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 8.w,
                      children: agent.tags.map((tag) => _buildTagChip(tag)).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24.r,
                ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildTagChip(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.primary,
        ),
      ),
    );
  }
  
  IconData _getIconData(String iconId) {
    switch (iconId) {
      case 'restaurant':
        return Icons.restaurant;
      case 'map':
        return Icons.map;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'headset_mic':
        return Icons.headset_mic;
      case 'search':
        return Icons.search;
      default:
        return Icons.smart_toy;
    }
  }
  
  Widget _buildTopSection() {
    return Obx(() {
      final agentId = controller.selectedAgent.value?.id;
      
      // 如果是网络搜索智能体，显示搜索相关功能区域
      if (agentId == 'web_search') {
        return Container(
          padding: EdgeInsets.all(16.r),
          color: Colors.grey[50],
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFeatureButton(Icons.medical_services, '健康知识'),
                  _buildFeatureButton(Icons.school, '教育资源'),
                  _buildFeatureButton(Icons.science, '科技新闻'),
                  _buildFeatureButton(Icons.help, '百科问答'),
                ],
              ),
            ],
          ),
        );
      }
      
      // 默认显示出行规划功能区域
      return Container(
        padding: EdgeInsets.all(16.r),
        color: Colors.grey[50],
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeatureButton(Icons.directions_car, '自驾游'),
                _buildFeatureButton(Icons.train, '火车票'),
                _buildFeatureButton(Icons.directions_bus, '汽车票'),
                _buildFeatureButton(Icons.hotel, '酒店'),
              ],
            ),
     
          ],
        ),
      );
    });
  }
  
  Widget _buildFeatureButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        controller.handleUserInput('请推荐$label相关信息');
      },
      child: Column(
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24.r,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Obx(() {
      final agentId = controller.selectedAgent.value?.id;
      
      IconData iconData = Icons.directions_car;
      String message = '点击上方功能按钮开始规划您的出行';
      
      if (agentId == 'web_search') {
        iconData = Icons.search;
        message = '点击上方功能按钮开始探索网络资讯';
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 80.r,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    });
  }
  
  Widget _buildMessageList() {
    return ListView.builder(
      controller: controller.scrollController.value,
      padding: EdgeInsets.all(16.r),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final content = message['content'] as String;
    final time = message['time'] as DateTime;
    final isThinking = content == '正在思考中...';
    
    // 判断是否为流式响应中的最后一条消息
    final isStreamingLastMessage = controller.isStreamResponding.value && 
                                  !isUser && 
                                  controller.messages.indexOf(message) == controller.messages.length - 1;

    // 尝试解析AI返回的JSON内容
    Map<String, dynamic>? aiResponse;
    List<Map<String, dynamic>>? products;
    List<Map<String, dynamic>>? addresses;
    List<Map<String, dynamic>>? orders;
    List<Map<String, dynamic>>? travelPlans;
    
    if (!isUser && !isThinking && !isStreamingLastMessage) {
      try {
        aiResponse = json.decode(content);
        if (aiResponse?['commands'] != null) {
          final commands = List<Map<String, dynamic>>.from(aiResponse!['commands']);
          debugPrint('commands: $commands');
          for (final command in commands) {
            if (command['found_products'] != null) {
              products = List<Map<String, dynamic>>.from(command['found_products']);
              break;
            }
            if (command['address_list'] != null) {
              addresses = List<Map<String, dynamic>>.from(command['address_list']);
              break;
            }
            if (command['order_list'] != null) {
              orders = List<Map<String, dynamic>>.from(command['order_list']);
              break;
            }
            if (command['travel_plans'] != null) {
              travelPlans = List<Map<String, dynamic>>.from(command['travel_plans']);
              break;
            }
          }
        }
      } catch (e) {
        // 解析失败，作为普通文本处理
        debugPrint('解析AI返回内容失败: $e');
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 显示发送者身份
          if (!isUser && controller.selectedAgent.value != null && !isThinking)
            Padding(
              padding: EdgeInsets.only(left: 48.w, bottom: 4.h),
              child: Row(
                children: [
                  Icon(
                    _getIconData(controller.selectedAgent.value!.iconId),
                    size: 16.r,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    controller.selectedAgent.value!.name,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isStreamingLastMessage)
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Row(
                        children: [
                          Container(
                            height: 8.r,
                            width: 8.r,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '正在输入...',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          // 用户消息则显示"您"
          if (isUser)
            Padding(
              padding: EdgeInsets.only(right: 48.w, bottom: 4.h),
              child: Text(
                "您",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    controller.selectedAgent.value != null 
                        ? _getIconData(controller.selectedAgent.value!.iconId) 
                        : Icons.directions_car, 
                    color: Colors.white
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser && aiResponse != null)
                        Text(
                          aiResponse['content'] ?? content,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                            fontSize: 14.sp,
                          ),
                        )
                      else if (isStreamingLastMessage)
                        Obx(() {
                          // 使用Obx监听流式响应内容变化
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarkdownBody(
                                data: controller.currentStreamResponse.value,
                                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(Get.context!)).copyWith(
                                  p: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14.sp,
                                  ),
                                  h1: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h2: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h3: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  code: TextStyle(
                                    fontSize: 13.sp,
                                    backgroundColor: Colors.grey[300],
                                  ),
                                  blockquote: TextStyle(
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  codeblockPadding: EdgeInsets.all(8.r),
                                  tableBody: TextStyle(fontSize: 14.sp),
                                  tableHead: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                                ),
                                selectable: true,
                                shrinkWrap: true,
                                fitContent: true,
                                builders: {
                                  'code': CodeElementBuilder(),
                                },
                                onTapLink: (text, href, title) {
                                  if (href != null) {
                                    _launchUrl(href);
                                  }
                                },
                              ),
                              if (controller.isStreamResponding.value) 
                                Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.4),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        })
                      else if (isUser)
                        Text(
                          content,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        )
                      else if (isThinking)
                        Row(
                          children: [
                            Text(
                              content,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            SizedBox(
                              width: 12.r,
                              height: 12.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ],
                        )
                      else
                        MarkdownBody(
                          data: content,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(Get.context!)).copyWith(
                            p: TextStyle(
                              color: Colors.black,
                              fontSize: 14.sp,
                            ),
                            h1: TextStyle(
                              color: Colors.black,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: TextStyle(
                              color: Colors.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: TextStyle(
                              color: Colors.black,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            code: TextStyle(
                              fontSize: 13.sp,
                              backgroundColor: Colors.grey[300],
                            ),
                            blockquote: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            codeblockPadding: EdgeInsets.all(8.r),
                            tableBody: TextStyle(fontSize: 14.sp),
                            tableHead: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                          ),
                          selectable: true,
                          shrinkWrap: true,
                          fitContent: true,
                          builders: {
                            'code': CodeElementBuilder(),
                          },
                          onTapLink: (text, href, title) {
                            if (href != null) {
                              _launchUrl(href);
                            }
                          },
                        ),
                      if (products != null && products.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        ...products.map((product) => _buildProductCard(product)),
                      ],
                      if (addresses != null && addresses.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        ...addresses.map((address) => _buildAddressCard(address)),
                      ],
                      if (orders != null && orders.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        ...orders.map((order) => _buildOrderCard(order)),
                      ],
                      if (travelPlans != null && travelPlans.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        ...travelPlans.map((plan) => _buildTravelPlanCard(plan)),
                      ],
                      SizedBox(height: 4.h),
                      Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isUser ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                SizedBox(width: 8.w),
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('无法打开链接 $url: $e');
      Get.snackbar('提示', '无法打开链接: $url', snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  Widget _buildProductCard(Map<String, dynamic> product) {
    // 安全获取字段值，避免空值异常
    final String imageUrl = product['image']?.toString() ?? '';
    final String name = product['name']?.toString() ?? '未知商品';
    final dynamic price = product['price'] ?? 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: imageUrl.isNotEmpty 
                ? Image.network(
                    imageUrl,
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60.w,
                        height: 60.w,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: 60.w,
                    height: 60.w,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '¥${price}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    // 安全获取字段值
    final String name = address['name']?.toString() ?? '';
    final String phone = address['phone']?.toString() ?? '';
    final bool isDefault = address['is_default'] == true;
    final String province = address['province']?.toString() ?? '';
    final String city = address['city']?.toString() ?? '';
    final String district = address['district']?.toString() ?? '';
    final String detail = address['detail']?.toString() ?? '';
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (phone.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (isDefault) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    '默认',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '$province $city $district $detail',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // 安全获取字段值
    final List<Map<String, dynamic>> items = order['items'] != null 
        ? List<Map<String, dynamic>>.from(order['items'])
        : [];
        
    // 如果items为空，返回空的Container避免异常
    if (items.isEmpty) {
      return Container();
    }
    
    final Map<String, dynamic> firstItem = items.first;
    final String orderNo = order['order_no']?.toString() ?? '未知订单号';
    final String status = _getOrderStatusText(order['status']?.toString() ?? '');
    final String productImage = firstItem['product_image']?.toString() ?? '';
    final String productName = firstItem['product_name']?.toString() ?? '未知商品';
    final dynamic price = firstItem['price'] ?? 0;
    final dynamic quantity = firstItem['quantity'] ?? 1;
    final dynamic totalAmount = order['total_amount'] ?? 0;
    
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.ORDER_DETAIL, 
        parameters: {'orderNo': orderNo}
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '订单号：$orderNo',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: productImage.isNotEmpty
                    ? Image.network(
                        productImage,
                        width: 60.w,
                        height: 60.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60.w,
                            height: 60.w,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 60.w,
                        height: 60.w,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '¥$price × $quantity${items.length > 1 ? ' 等${items.length}件商品' : ''}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '实付：',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '¥$totalAmount',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTravelPlanCard(Map<String, dynamic> plan) {
    // 安全获取字段值
    final String title = plan['title']?.toString() ?? '旅行计划';
    final String? description = plan['description']?.toString();
    final String? dateRange = plan['date_range']?.toString();
    final String? location = plan['location']?.toString();
    final String? price = plan['price']?.toString();
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_takeoff, color: AppColors.primary, size: 18.r),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (description != null && description.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
            ),
          if (dateRange != null && dateRange.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16.r, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (location != null && location.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16.r, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (price != null && price.isNotEmpty)
            Row(
              children: [
                Icon(Icons.monetization_on, size: 16.r, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    '价格: $price',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  String _getOrderStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return '待付款';
      case 'pending_delivery':
        return '待发货';
      case 'pending_receipt':
        return '待收货';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '未知状态';
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.psychology, color: AppColors.textSecondary),
              onPressed: controller.isAiResponding.value ? null : _showAgentList,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 40.w,
                minHeight: 40.h,
              ),
            ),
    
            SizedBox(width: 8.w),
            Expanded(
              child: TextField(
                controller: controller.textController,
                enabled: !controller.isAiResponding.value,
                decoration: InputDecoration(
                  hintText: controller.isAiResponding.value 
                      ? (controller.isStreamResponding.value ? '正在回答中...' : '正在思考中...') 
                      : '输入您的出行需求...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !controller.isAiResponding.value) {
                    controller.handleUserInput(value);
                  }
                },
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() => controller.isStreamResponding.value
                ? IconButton(
                    icon: Icon(Icons.stop, color: Colors.red),
                    onPressed: controller.stopExecution,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 40.w,
                      minHeight: 40.h,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.send, 
                      color: controller.isAiResponding.value || controller.textController.text.isEmpty 
                          ? Colors.grey 
                          : AppColors.primary
                    ),
                    onPressed: controller.isAiResponding.value 
                        ? null 
                        : () {
                            final text = controller.textController.text.trim();
                            if (text.isNotEmpty) {
                              controller.handleUserInput(text);
                            }
                          },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 40.w,
                      minHeight: 40.h,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
} 