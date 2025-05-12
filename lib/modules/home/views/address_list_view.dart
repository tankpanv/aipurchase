import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/address_controller.dart';
import '../../../models/address.dart';
import '../../../routes/app_pages.dart';

class AddressListView extends GetView<AddressController> {
  const AddressListView({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保 AddressController 已注册
    if (!Get.isRegistered<AddressController>()) {
      Get.put(AddressController());
    }
    
    // 获取参数
    final bool selectMode = Get.arguments?['selectMode'] ?? false;
    final Function(Address)? onSelected = Get.arguments?['onSelected'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(selectMode ? '选择收货地址' : '收货地址'),
        actions: [
          TextButton(
            onPressed: () => Get.toNamed(Routes.ADDRESS_EDIT),
            child: Text(
              '新增',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 48.r,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '暂无收货地址',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(16.r),
                    itemCount: controller.addresses.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final address = controller.addresses[index];
                      return _buildAddressCard(
                        address,
                        selectMode: selectMode,
                        onSelected: onSelected,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildAddressCard(
    Address address, {
    bool selectMode = false,
    Function(Address)? onSelected,
  }) {
    return InkWell(
      onTap: selectMode && onSelected != null
          ? () {
              onSelected(address);
              Get.back();
            }
          : null,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  address.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 16.w),
                Text(
                  address.phone,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (address.isDefault) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
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
              '${address.province}${address.city}${address.district}${address.detail}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
              ),
            ),
            if (!selectMode) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  if (!address.isDefault)
                    GestureDetector(
                      onTap: () => controller.setDefaultAddress(address.id!),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20.r,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '设为默认',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.toNamed(
                      Routes.ADDRESS_EDIT,
                      arguments: address,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20.r,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '编辑',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  GestureDetector(
                    onTap: () => _showDeleteDialog(address),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20.r,
                          color: Colors.red,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '删除',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Address address) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除该收货地址吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAddress(address.id!);
            },
            child: const Text(
              '确认',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 