import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';

class OrderDetailView extends GetView<OrderController> {
  final String orderNo;

  const OrderDetailView({super.key, required this.orderNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单详情'),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.getOrderDetail(orderNo),
        child: FutureBuilder<Order>(
          future: controller.getOrderDetail(orderNo),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint('订单详情加载失败: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('加载失败：${snapshot.error}'),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => controller.getOrderDetail(orderNo),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.data == null) {
              return const Center(
                child: Text('订单数据为空，请返回重试'),
              );
            }

            final order = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(order),
                  SizedBox(height: 16.h),
                  if (order.address != null) _buildAddressCard(order.address!),
                  SizedBox(height: 16.h),
                  _buildOrderItems(order.items),
                  SizedBox(height: 16.h),
                  _buildOrderInfo(order),
                  SizedBox(height: 24.h),
                  _buildActionButtons(order),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 32.w,
              color: order.statusColor,
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.statusText,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: order.statusColor,
                  ),
                ),
                if (order.status == 'pending_receipt')
                  Text(
                    '预计送达时间：3-5天',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(OrderAddress address) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined),
                SizedBox(width: 8.w),
                Text(
                  '收货地址',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.w),
            Text(
              address.name,
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 4.w),
            Text(
              address.phone,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4.w),
            Text(
              address.fullAddress,
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(List<OrderItem> items) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined),
                SizedBox(width: 8.w),
                Text(
                  '商品信息',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.w),
            child: item.product.mainImageUrl.isNotEmpty
                ? Image.network(
                    item.product.mainImageUrl,
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImageError(),
                  )
                : _buildImageError(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '¥${item.price}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '数量：${item.quantity}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      width: 80.w,
      height: 80.w,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 32.w,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildOrderInfo(Order order) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                SizedBox(width: 8.w),
                Text(
                  '订单信息',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.w),
            _buildInfoRow('订单编号', order.orderNo),
            _buildInfoRow('创建时间', order.createdAt),
            if (order.paymentTime != null)
              _buildInfoRow('支付时间', order.paymentTime!),
            if (order.shippingTime != null)
              _buildInfoRow('发货时间', order.shippingTime!),
            if (order.receiptTime != null)
              _buildInfoRow('收货时间', order.receiptTime!),
            if (order.remarks != null) _buildInfoRow('备注', order.remarks!),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '实付：',
                  style: TextStyle(fontSize: 14.sp),
                ),
                Text(
                  '¥${order.totalAmount}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: Row(
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (order.status == 'pending_payment') ...[
          OutlinedButton(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('确认取消'),
                  content: const Text('确定要取消该订单吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('再想想'),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        controller.cancelOrder(order.orderNo);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('取消订单'),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: () => controller.payOrder(order.orderNo),
            child: const Text('立即支付'),
          ),
        ] else if (order.status == 'pending_receipt') ...[
          ElevatedButton(
            onPressed: () => controller.confirmReceipt(order.orderNo),
            child: const Text('确认收货'),
          ),
        ],
      ],
    );
  }
} 