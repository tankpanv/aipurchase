import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../widgets/empty_placeholder.dart';
import '../../../routes/app_pages.dart';

class OrdersView extends GetView<OrderController> {
  final String? initialStatus;

  const OrdersView({super.key, this.initialStatus});

  @override
  Widget build(BuildContext context) {
    // 确保在页面加载时获取订单列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = initialStatus;
      controller.fetchOrders(status: status, refresh: true);
    });

    return DefaultTabController(
      length: 5,
      initialIndex: _getInitialIndex(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的订单'),
          bottom: TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: '全部'),
              Tab(text: '待付款'),
              Tab(text: '待发货'),
              Tab(text: '待收货'),
              Tab(text: '已完成'),
            ],
            onTap: (index) {
              final status = index == 0 ? null : ['pending_payment', 'pending_delivery', 'pending_receipt', 'completed'][index - 1];
              controller.fetchOrders(status: status, refresh: true);
            },
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(),
            _buildOrderList(status: 'pending_payment'),
            _buildOrderList(status: 'pending_delivery'),
            _buildOrderList(status: 'pending_receipt'),
            _buildOrderList(status: 'completed'),
          ],
        ),
      ),
    );
  }

  int _getInitialIndex() {
    if (initialStatus == null) return 0;
    final statusList = ['pending_payment', 'pending_delivery', 'pending_receipt', 'completed'];
    final index = statusList.indexOf(initialStatus!);
    return index == -1 ? 0 : index + 1;
  }

  Widget _buildOrderList({String? status}) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchOrders(status: status, refresh: true),
      child: Obx(() {
        if (controller.isLoading.value && controller.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.error.value),
                ElevatedButton(
                  onPressed: () => controller.fetchOrders(status: status, refresh: true),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (controller.orders.isEmpty) {
          return EmptyPlaceholder(
            icon: Icons.receipt_long_outlined,
            message: '暂无订单',
            onRefresh: () => controller.fetchOrders(status: status, refresh: true),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.orders.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.orders.length) {
              if (controller.hasMore.value) {
                controller.fetchOrders(status: status);
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: const CircularProgressIndicator(),
                  ),
                );
              }
              return const SizedBox();
            }

            final order = controller.orders[index];
            return _buildOrderCard(order);
          },
        );
      }),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.w),
      child: InkWell(
        onTap: () => Get.toNamed(
          Routes.ORDER_DETAIL,
          parameters: {'orderNo': order.orderNo},
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '订单号：${order.orderNo}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    order.statusText,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: order.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.w),
              ...order.items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 8.w),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.w),
                      child: Image.network(
                        item.product.mainImageUrl,
                        width: 60.w,
                        height: 60.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60.w,
                          height: 60.w,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 24.w,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
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
                          SizedBox(height: 4.w),
                          Text(
                            '¥${item.price} × ${item.quantity}',
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
              )),
              Divider(height: 24.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共${order.items.length}件商品',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '实付：¥${order.totalAmount}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == 'pending_payment') ...[
                    OutlinedButton(
                      onPressed: () => controller.cancelOrder(order.orderNo),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
} 