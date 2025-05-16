import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/ai_chat_controller.dart';
import 'agent_list_view.dart';
import 'command_list_view.dart';
import 'chat_markdown_view.dart';
import '../../../utils/command_executor.dart';
import 'dart:convert';
import '../../../widgets/ai_product_card.dart';
import '../../../routes/app_pages.dart';

class AIChatView extends GetView<AIChatController> {
  const AIChatView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI助手',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.psychology, size: 24.r),
            onPressed: _showAgentList,
            tooltip: '智能体列表',
          ),
          IconButton(
            icon: Icon(Icons.format_list_bulleted, size: 24.r),
            onPressed: () => Get.to(() => const ChatMarkdownView()),
            tooltip: 'Markdown视图',
          ),
          IconButton(
            icon: Icon(Icons.history, size: 24.r),
            onPressed: () {
              // TODO: 显示历史对话记录
            },
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
          Expanded(
            child: Obx(() => ListView.builder(
              controller: controller.scrollController.value,
              padding: EdgeInsets.all(16.r),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final message = controller.messages[index];
                return _buildMessageBubble(message);
              },
            )),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showAgentList() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AgentListView(
          controller: controller,
          onAgentSelected: () => Get.back(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final content = message['content'] as String;
    final time = message['time'] as DateTime;
    final isThinking = content == '正在思考中...';
    final sender = message['sender'] as String;

    // 尝试解析AI返回的JSON内容
    Map<String, dynamic>? aiResponse;
    List<Map<String, dynamic>>? products;
    List<Map<String, dynamic>>? addresses;
    List<Map<String, dynamic>>? orders;
    
    if (!isUser && !isThinking) {
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
          
          }
        }
      } catch (e) {
        // 解析失败，作为普通文本处理
        print('解析AI返回内容失败: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 显示发送者身份（对于AI回复）
          if (!isUser && controller.selectedAgent.value != null && !isThinking)
            Padding(
              padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
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
                ],
              ),
            ),
          // 用户消息则显示"您"
          if (isUser)
            Padding(
              padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
              child: Text(
                "您",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser && aiResponse != null)
                  Text(aiResponse['content'] ?? content)
                else
                  Text(content),
                if (products != null && products.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...products.map((product) => AIProductCard(product: product)),
                ],
                if (addresses != null && addresses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...addresses.map((address) => _buildAddressCard(address)),
                ],
                if (orders != null && orders.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...orders.map((order) => _buildOrderCard(order)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${time.hour}:${time.minute}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
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
              Text(
                address['name'] ?? '',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                address['phone'] ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              if (address['is_default'] == true) ...[
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
            '${address['province']} ${address['city']} ${address['district']} ${address['detail']}',
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
    final items = List<Map<String, dynamic>>.from(order['items']);
    final firstItem = items.first;
    final status = _getOrderStatusText(order['status'] as String);
    
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.ORDER_DETAIL, 
        parameters: {'orderNo': order['order_no']}
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
                  '订单号：${order['order_no']}',
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
                  child: Image.network(
                    firstItem['product_image'],
                    width: 60.w,
                    height: 60.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem['product_name'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '¥${firstItem['price']} × ${firstItem['quantity']}${items.length > 1 ? ' 等${items.length}件商品' : ''}',
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
                  '¥${order['total_amount']}',
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
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextField(
                  controller: controller.textController,
                  enabled: !controller.isAiResponding.value,
                  decoration: InputDecoration(
                    hintText: controller.isAiResponding.value ? '正在回答中...' : '输入您的需求...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                  onSubmitted: (value) {
                    final text = value.trim();
                    if (text.isNotEmpty && !controller.isAiResponding.value) {
                      controller.handleUserInput(text);
                    }
                  },
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() => IconButton(
              icon: Icon(
                Icons.send,
                color: controller.textController.text.trim().isEmpty || controller.isAiResponding.value
                    ? AppColors.textHint
                    : AppColors.primary,
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
            )),
          ],
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
      default:
        return Icons.smart_toy;
    }
  }
} 