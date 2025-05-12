import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';

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
                  Text(
                    content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 14.sp,
                    ),
                  ),
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
            onPressed: controller.startVoiceInput,
          ),
          Expanded(
            child: TextField(
              controller: controller.textController,
              decoration: InputDecoration(
                hintText: '输入您的出行需求...',
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
                if (value.isNotEmpty) {
                  controller.handleUserInput(value);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: () {
              final text = controller.textController.text;
              if (text.isNotEmpty) {
                controller.handleUserInput(text);
              }
            },
          ),
        ],
      ),
    );
  }
} 