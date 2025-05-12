import 'package:flutter/material.dart';

class Order {
  final int id;
  final String orderNo;
  final double totalAmount;
  final String status;
  final String? remarks;
  final String createdAt;
  final String? paymentTime;
  final String? shippingTime;
  final String? receiptTime;
  final String? refundReason;
  final List<OrderItem> items;
  final OrderAddress? address;

  Order({
    required this.id,
    required this.orderNo,
    required this.totalAmount,
    required this.status,
    this.remarks,
    required this.createdAt,
    this.paymentTime,
    this.shippingTime,
    this.receiptTime,
    this.refundReason,
    required this.items,
    this.address,
  });

  String get statusText {
    switch (status) {
      case 'pending_payment':
        return '待付款';
      case 'pending_delivery':
        return '待发货';
      case 'pending_receipt':
        return '待收货';
      case 'pending_review':
        return '待评价';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'refunding':
        return '退款中';
      default:
        return '未知状态';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending_payment':
        return Colors.red;
      case 'pending_delivery':
      case 'pending_receipt':
        return Colors.blue;
      case 'pending_review':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'refunding':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNo: json['order_no'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      remarks: json['remarks'],
      createdAt: json['created_at'],
      paymentTime: json['payment_time'],
      shippingTime: json['shipping_time'],
      receiptTime: json['receipt_time'],
      refundReason: json['refund_reason'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      address: json['address'] != null
          ? OrderAddress.fromJson(json['address'])
          : null,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int quantity;
  final double price;
  final double subtotal;
  final String createdAt;
  final String updatedAt;
  final OrderProduct product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      product: OrderProduct.fromJson(json['product']),
    );
  }
}

class OrderProduct {
  final int id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String mainImageUrl;
  final String productType;
  final String status;
  final int stock;
  final String unit;
  final List<String> flavor;
  final String? spec;
  final String? discount;
  final List<String> tag;
  final bool isFeatured;
  final String createdAt;
  final String updatedAt;
  final String publishedAt;
  final List<String> detailImages;

  OrderProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.mainImageUrl,
    required this.productType,
    required this.status,
    required this.stock,
    required this.unit,
    required this.flavor,
    this.spec,
    this.discount,
    required this.tag,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    required this.publishedAt,
    required this.detailImages,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num).toDouble(),
      mainImageUrl: json['main_image_url'],
      productType: json['product_type'] ?? '',
      status: json['status'],
      stock: json['stock'],
      unit: json['unit'],
      flavor: json['flavor'] is List 
          ? List<String>.from(json['flavor'])
          : json['flavor'] != null 
              ? [json['flavor'].toString()]
              : [],
      spec: json['spec'],
      discount: json['discount'],
      tag: json['tag'] is List 
          ? List<String>.from(json['tag'])
          : json['tag'] != null 
              ? [json['tag'].toString()]
              : [],
      isFeatured: json['is_featured'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      publishedAt: json['published_at'],
      detailImages: json['detail_images'] is List 
          ? List<String>.from(json['detail_images'])
          : [],
    );
  }
}

class OrderAddress {
  final int id;
  final String name;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String detail;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  OrderAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.province,
    required this.city,
    required this.district,
    required this.detail,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress => '$province$city$district$detail';

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      province: json['province'],
      city: json['city'],
      district: json['district'],
      detail: json['detail'],
      isDefault: json['is_default'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class OrdersResponse {
  final int code;
  final String message;
  final List<Order> orders;
  final int total;
  final int pages;
  final int currentPage;

  OrdersResponse({
    required this.code,
    required this.message,
    required this.orders,
    required this.total,
    required this.pages,
    required this.currentPage,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      return OrdersResponse(
        code: json['code'] ?? 400,
        message: json['message'] ?? '请求失败',
        orders: [],
        total: 0,
        pages: 1,
        currentPage: 1,
      );
    }

    List<Order> orders = [];
    if (data['items'] != null) {
      try {
        orders = (data['items'] as List)
            .map((item) => Order.fromJson(item))
            .toList();
      } catch (e) {
        debugPrint('解析订单数据失败: $e');
      }
    }

    return OrdersResponse(
      code: json['code'] ?? 200,
      message: json['message'] ?? '请求失败',
      orders: orders,
      total: data['total'] ?? 0,
      pages: data['pages'] ?? 1,
      currentPage: data['current_page'] ?? 1,
    );
  }
} 