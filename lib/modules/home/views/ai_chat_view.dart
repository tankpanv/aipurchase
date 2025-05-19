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
    String displayContent = content;
    bool isJsonResponse = false;
    
    if (!isUser && !isThinking) {
      try {
        // 检查内容是否以{开头和}结尾，这是JSON的特征
        if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
          aiResponse = json.decode(content);
          isJsonResponse = true;
          
          // 提取显示内容
          if (aiResponse?['content'] != null) {
            displayContent = aiResponse!['content'].toString();
          }
          
          if (aiResponse?['commands'] != null) {
            final commands = List<Map<String, dynamic>>.from(aiResponse!['commands']);
            debugPrint('commands: $commands');
            for (final command in commands) {
              if (command['found_products'] != null) {
                products = List<Map<String, dynamic>>.from(command['found_products']);
              }
              if (command['address_list'] != null) {
                addresses = List<Map<String, dynamic>>.from(command['address_list']);
              }
              if (command['order_list'] != null) {
                orders = List<Map<String, dynamic>>.from(command['order_list']);
              }
            }
          }
        } else if (content.contains('commands:') || content.contains('address_list:') || content.contains('order_list:')) {
          // 可能是特殊格式的命令数据，记录日志但不尝试解析
          debugPrint('检测到可能的命令或列表数据，作为普通文本处理: $content');
          displayContent = content;
        }
      } catch (e) {
        // 解析失败，作为普通文本处理
        debugPrint('解析AI返回内容失败: $e');
        displayContent = content;
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
                if (!isUser && isJsonResponse && aiResponse != null)
                  Text(displayContent)
                else
                  Text(displayContent),
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
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
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
    try {
      // 安全获取字段值
      final String orderNo = order['order_no']?.toString() ?? '未知订单号';
      final String status = _getOrderStatusText(order['status']?.toString() ?? '');
      final dynamic totalAmount = order['total_amount'] ?? 0;
      
      // 处理订单项
      final List<Map<String, dynamic>> items = [];
      if (order['items'] != null) {
        try {
          items.addAll(List<Map<String, dynamic>>.from(order['items']));
        } catch (e) {
          debugPrint('订单项解析失败: $e');
        }
      }
          
      // 如果items为空，显示基本订单信息
      if (items.isEmpty) {
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
              Text(
                '暂无商品数据',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
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
        );
      }
      
      // 安全获取第一个商品信息
      Map<String, dynamic> firstItem;
      try {
        firstItem = items.first;
      } catch (e) {
        debugPrint('获取第一个商品失败: $e');
        firstItem = {};
      }
      
      // 检查是否是新的数据结构(有product字段)
      bool isNewStructure = firstItem.containsKey('product') && firstItem['product'] is Map;
      bool isDeletedProduct = firstItem.containsKey('deleted_product') && firstItem['deleted_product'] is Map;
      
      // 获取商品信息
      String productName = '未知商品';
      String productImage = '';
      dynamic price = 0;
      dynamic quantity = 1;
      
      try {
        if (isNewStructure) {
          // 新数据结构，从product字段中获取信息
          final product = firstItem['product'] as Map<String, dynamic>? ?? {};
          productName = product['name']?.toString() ?? '未知商品';
          productImage = product['main_image_url']?.toString() ?? '';
          price = firstItem['price'] ?? product['price'] ?? 0;
          quantity = firstItem['quantity'] ?? 1;
        } else if (isDeletedProduct) {
          // 已删除商品结构
          final deletedProduct = firstItem['deleted_product'] as Map<String, dynamic>? ?? {};
          productName = deletedProduct['product_name']?.toString() ?? '已删除商品';
          productImage = '';
          price = firstItem['price'] ?? deletedProduct['price'] ?? 0;
          quantity = firstItem['quantity'] ?? 1;
        } else {
          // 旧数据结构，直接从item中获取
          productName = firstItem['product_name']?.toString() ?? '未知商品';
          productImage = firstItem['product_image']?.toString() ?? '';
          price = firstItem['price'] ?? 0;
          quantity = firstItem['quantity'] ?? 1;
        }
      } catch (e) {
        debugPrint('解析商品信息失败: $e');
        productName = '商品信息解析失败';
      }
      
      debugPrint('订单: $orderNo, 状态: $status, 商品: $productName, 价格: $price, 数量: $quantity');
      
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((productImage ?? '').trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: Image.network(
                        productImage,
                        width: 60.w,
                        height: 60.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 图片加载失败时直接不显示图片区域
                          return SizedBox.shrink();
                        },
                      ),
                    ),
                  if ((productImage ?? '').trim().isNotEmpty)
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
    } catch (e) {
      debugPrint('构建订单卡片失败: $e');
      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Text(
          '订单数据解析失败',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.red,
          ),
        ),
      );
    }
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