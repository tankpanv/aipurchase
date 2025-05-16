import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import 'dart:convert';
import '../../../widgets/ai_product_card.dart';
import '../../../routes/app_pages.dart';
import 'chat_travel_markdown_view.dart';

import '../controllers/ai_travel_assistant_controller.dart';

class AiAssistantTravelView extends GetView<AiTravelAssistantController> {
  const AiAssistantTravelView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('出行规划助手'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted, color: Colors.white),
            onPressed: () => Get.to(() => const ChatTravelMarkdownView()),
            tooltip: 'Markdown视图',
          ),
        ],
      ),
      body: Column(
        children: [
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
  
  Widget _buildTopSection() {
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
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeatureButton(Icons.airplanemode_active, '机票'),
              _buildFeatureButton(Icons.map, '景点门票'),
              _buildFeatureButton(Icons.restaurant, '美食推荐'),
              _buildFeatureButton(Icons.location_on, '周边游'),
            ],
          ),
        ],
      ),
    );
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 80.r,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            '点击上方功能按钮开始规划您的出行',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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

    // 尝试解析AI返回的JSON内容
    Map<String, dynamic>? aiResponse;
    List<Map<String, dynamic>>? products;
    List<Map<String, dynamic>>? addresses;
    List<Map<String, dynamic>>? orders;
    List<Map<String, dynamic>>? travelPlans;
    
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
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.directions_car, color: Colors.white),
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
                  else
                  Text(
                    content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                        fontSize: 14.sp,
                    ),
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
    );
  }
  
  Widget _buildProductCard(Map<String, dynamic> product) {
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
            child: Image.network(
              product['image'],
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
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '¥${product['price']}',
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60.w,
                        height: 60.w,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
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
  
  Widget _buildTravelPlanCard(Map<String, dynamic> plan) {
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
              Text(
                plan['title'] ?? '旅行计划',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (plan['description'] != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                plan['description'],
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
            ),
          if (plan['date_range'] != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16.r, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    plan['date_range'],
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          if (plan['location'] != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16.r, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    plan['location'],
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          if (plan['price'] != null)
            Row(
              children: [
                Icon(Icons.monetization_on, size: 16.r, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  '价格: ${plan['price']}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
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
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic, color: AppColors.primary),
            onPressed: controller.isAiResponding.value ? null : controller.startVoiceInput,
          ),
          Expanded(
            child: TextField(
              controller: controller.textController,
              enabled: !controller.isAiResponding.value,
              decoration: InputDecoration(
                hintText: controller.isAiResponding.value ? '正在回答中...' : '输入您的出行需求...',
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
          Obx(() => IconButton(
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
          )),
        ],
      ),
    );
  }
} 