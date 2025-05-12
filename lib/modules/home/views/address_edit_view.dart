import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/address_controller.dart';
import '../../../models/address.dart';

class AddressEditView extends GetView<AddressController> {
  final Address? address = Get.arguments;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _detailController = TextEditingController();
  final _isDefault = false.obs;

  AddressEditView({super.key}) {
    if (address != null) {
      _nameController.text = address!.name;
      _phoneController.text = address!.phone;
      _provinceController.text = address!.province;
      _cityController.text = address!.city;
      _districtController.text = address!.district;
      _detailController.text = address!.detail;
      _isDefault.value = address!.isDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(address == null ? '新增地址' : '编辑地址'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _buildTextFormField(
              controller: _nameController,
              label: '收货人',
              hintText: '请输入收货人姓名',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入收货人姓名';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildTextFormField(
              controller: _phoneController,
              label: '手机号码',
              hintText: '请输入手机号码',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号码';
                }
                if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                  return '请输入正确的手机号码';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _provinceController,
                    label: '省份',
                    hintText: '请选择',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择省份';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildTextFormField(
                    controller: _cityController,
                    label: '城市',
                    hintText: '请选择',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请选择城市';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildTextFormField(
              controller: _districtController,
              label: '区/县',
              hintText: '请选择',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请选择区/县';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildTextFormField(
              controller: _detailController,
              label: '详细地址',
              hintText: '请输入详细地址，如街道、门牌号等',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入详细地址';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),
            Obx(
              () => SwitchListTile(
                value: _isDefault.value,
                onChanged: (value) => _isDefault.value = value,
                title: Text(
                  '设为默认地址',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
                activeColor: AppColors.primary,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                '保存',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: AppColors.primary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textPrimary,
          ),
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          validator: validator,
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newAddress = Address(
        name: _nameController.text,
        phone: _phoneController.text,
        province: _provinceController.text,
        city: _cityController.text,
        district: _districtController.text,
        detail: _detailController.text,
        isDefault: _isDefault.value,
      );

      if (address == null) {
        controller.createAddress(newAddress);
      } else {
        controller.updateAddress(address!.id!, newAddress);
      }
    }
  }
} 