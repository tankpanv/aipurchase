import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/ai_chat_controller.dart';
import '../../../models/agent_model.dart';

class AgentListView extends StatelessWidget {
  final AIChatController controller;
  final VoidCallback onAgentSelected;

  const AgentListView({
    Key? key,
    required this.controller,
    required this.onAgentSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            child: Obx(() => ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: controller.availableAgents.length,
              itemBuilder: (context, index) {
                final agent = controller.availableAgents[index];
                return _buildAgentItem(agent);
              },
            )),
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
          onAgentSelected();
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
      default:
        return Icons.smart_toy;
    }
  }
} 