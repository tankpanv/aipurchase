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
  final int? userId;

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
    this.userId,
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
    try {
      debugPrint('开始解析Order: ${json['order_no']}');
      // 确保ID字段不为null
      int id = 0;
      if (json['id'] != null) {
        if (json['id'] is int) {
          id = json['id'];
        } else if (json['id'] is String) {
          id = int.tryParse(json['id']) ?? 0;
        }
      }
      
      // 安全处理总金额，考虑它可能是String类型
      double totalAmount = 0.0;
      if (json['total_amount'] != null) {
        if (json['total_amount'] is num) {
          totalAmount = (json['total_amount'] as num).toDouble();
        } else if (json['total_amount'] is String) {
          totalAmount = double.tryParse(json['total_amount'].toString()) ?? 0.0;
        }
      }
      
      // 处理订单状态
      String status = json['status'] ?? 'unknown';
      
      // 安全处理订单项
      List<OrderItem> orderItems = [];
      if (json['items'] != null && json['items'] is List) {
        try {
          orderItems = (json['items'] as List)
              .map((item) {
                try {
                  return OrderItem.fromJson(item);
                } catch (e) {
                  debugPrint('解析订单项失败: $e, item: $item');
                  return null;
                }
              })
              .where((item) => item != null)
              .cast<OrderItem>()
              .toList();
        } catch (e) {
          debugPrint('解析订单项列表失败: $e');
        }
      }
      
      // 处理用户ID
      int? userId;
      if (json['user_id'] != null) {
        if (json['user_id'] is int) {
          userId = json['user_id'];
        } else if (json['user_id'] is String) {
          userId = int.tryParse(json['user_id']);
        }
      }
      
      return Order(
        id: id,
        orderNo: json['order_no'] ?? '',
        totalAmount: totalAmount,
        status: status,
        remarks: json['remarks'],
        createdAt: json['created_at'] ?? '',
        paymentTime: json['payment_time'],
        shippingTime: json['shipping_time'],
        receiptTime: json['receipt_time'],
        refundReason: json['refund_reason'],
        items: orderItems,
        address: json['address'] != null
            ? OrderAddress.fromJson(json['address'])
            : null,
        userId: userId,
      );
    } catch (e, stackTrace) {
      debugPrint('Order解析失败: $e');
      debugPrint('Order异常堆栈: $stackTrace');
      debugPrint('Order原始数据: $json');
      
      // 返回一个默认的订单对象，避免应用崩溃
      return Order(
        id: 0,
        orderNo: json['order_no'] ?? '未知订单号',
        totalAmount: 0.0,
        status: 'unknown',
        createdAt: '',
        items: [],
      );
    }
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
    // 处理已删除商品的情况
    if (json.containsKey('deleted_product') && json['product'] == null) {
      // 已删除商品使用deleted_product信息创建一个虚拟商品
      Map<String, dynamic> deletedProduct = json['deleted_product'] as Map<String, dynamic>? ?? {};
      String productName = deletedProduct['product_name']?.toString() ?? '已删除商品';
      
      // 确保价格转换安全，处理可能是String类型的price
      double productPrice = 0.0;
      if (deletedProduct['price'] != null) {
        if (deletedProduct['price'] is num) {
          productPrice = (deletedProduct['price'] as num).toDouble();
        } else if (deletedProduct['price'] is String) {
          productPrice = double.tryParse(deletedProduct['price']) ?? 0.0;
        }
      }
      
      int productId = (deletedProduct['product_id'] as num?)?.toInt() ?? 0;
      
      // 创建一个虚拟商品对象
      Map<String, dynamic> virtualProduct = {
        'id': productId,
        'name': productName,
        'description': '此商品已被删除',
        'price': productPrice,
        'original_price': productPrice,
        'main_image_url': '',
        'product_type': 'deleted',
        'status': 'deleted',
        'stock': 0,
        'unit': '件',
        'flavor': [],
        'tag': [],
        'is_featured': false,
        'created_at': json['created_at'] ?? '',
        'updated_at': json['updated_at'] ?? '',
        'published_at': '',
        'detail_images': [],
      };
      
      // 安全处理价格和小计，考虑它们可能是String类型
      double price = 0.0;
      if (json['price'] != null) {
        if (json['price'] is num) {
          price = (json['price'] as num).toDouble();
        } else if (json['price'] is String) {
          price = double.tryParse(json['price'].toString()) ?? productPrice;
        }
      } else {
        price = productPrice;
      }
      
      double subtotal = 0.0;
      if (json['subtotal'] != null) {
        if (json['subtotal'] is num) {
          subtotal = (json['subtotal'] as num).toDouble();
        } else if (json['subtotal'] is String) {
          subtotal = double.tryParse(json['subtotal'].toString()) ?? (price * (json['quantity'] ?? 1));
        }
      } else {
        subtotal = price * (json['quantity'] ?? 1);
      }
      
      return OrderItem(
        id: json['id'],
        orderId: json['order_id'],
        quantity: json['quantity'] ?? 1,
        price: price,
        subtotal: subtotal,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        product: OrderProduct.fromJson(virtualProduct),
      );
    }
    
    // 正常商品处理 - 同样安全处理价格和小计
    double price = 0.0;
    if (json['price'] != null) {
      if (json['price'] is num) {
        price = (json['price'] as num).toDouble();
      } else if (json['price'] is String) {
        price = double.tryParse(json['price'].toString()) ?? 0.0;
      }
    }
    
    double subtotal = 0.0;
    if (json['subtotal'] != null) {
      if (json['subtotal'] is num) {
        subtotal = (json['subtotal'] as num).toDouble();
      } else if (json['subtotal'] is String) {
        subtotal = double.tryParse(json['subtotal'].toString()) ?? (price * (json['quantity'] ?? 1));
      }
    } else {
      subtotal = price * (json['quantity'] ?? 1);
    }
    
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      quantity: json['quantity'],
      price: price,
      subtotal: subtotal,
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
    try {
      // 安全处理价格，考虑它可能是String类型
      double price = 0.0;
      if (json['price'] != null) {
        if (json['price'] is num) {
          price = (json['price'] as num).toDouble();
        } else if (json['price'] is String) {
          price = double.tryParse(json['price'].toString()) ?? 0.0;
        }
      }
      
      // 安全处理原价，考虑它可能是String类型
      double originalPrice = 0.0;
      if (json['original_price'] != null) {
        if (json['original_price'] is num) {
          originalPrice = (json['original_price'] as num).toDouble();
        } else if (json['original_price'] is String) {
          originalPrice = double.tryParse(json['original_price'].toString()) ?? 0.0;
        }
      }
      
      return OrderProduct(
        id: json['id'] ?? 0,
        name: json['name'] ?? '未知商品',
        description: json['description'] ?? '',
        price: price,
        originalPrice: originalPrice,
        mainImageUrl: json['main_image_url'] ?? '',
        productType: json['product_type'] ?? '',
        status: json['status'] ?? 'unknown',
        stock: json['stock'] ?? 0,
        unit: json['unit'] ?? '件',
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
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        publishedAt: json['published_at'] ?? '',
        detailImages: json['detail_images'] is List 
            ? List<String>.from(json['detail_images'])
            : [],
      );
    } catch (e) {
      // 如果解析失败，返回一个默认的商品对象
      debugPrint('OrderProduct解析失败: $e, json: $json');
      return OrderProduct(
        id: json['id'] ?? 0,
        name: '商品数据错误',
        description: '无法解析的商品数据',
        price: 0.0,
        originalPrice: 0.0,
        mainImageUrl: '',
        productType: 'error',
        status: 'error',
        stock: 0,
        unit: '件',
        flavor: [],
        tag: [],
        isFeatured: false,
        createdAt: '',
        updatedAt: '',
        publishedAt: '',
        detailImages: [],
      );
    }
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
    try {
      // 安全解析ID
      int id = 0;
      if (json['id'] != null) {
        if (json['id'] is int) {
          id = json['id'];
        } else if (json['id'] is String) {
          id = int.tryParse(json['id'].toString()) ?? 0;
        }
      }
      
      // 安全处理布尔值
      bool isDefault = false;
      if (json['is_default'] != null) {
        if (json['is_default'] is bool) {
          isDefault = json['is_default'];
        } else if (json['is_default'] is int) {
          isDefault = json['is_default'] == 1;
        } else if (json['is_default'] is String) {
          isDefault = json['is_default'].toLowerCase() == 'true' || json['is_default'] == '1';
        }
      }
      
      return OrderAddress(
        id: id,
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        province: json['province'] ?? '',
        city: json['city'] ?? '',
        district: json['district'] ?? '',
        detail: json['detail'] ?? '',
        isDefault: isDefault,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
      );
    } catch (e, stackTrace) {
      debugPrint('OrderAddress解析失败: $e');
      debugPrint('OrderAddress异常堆栈: $stackTrace');
      debugPrint('OrderAddress原始数据: $json');
      
      // 返回一个默认对象避免崩溃
      return OrderAddress(
        id: 0,
        name: json['name'] ?? '未知收件人',
        phone: json['phone'] ?? '',
        province: json['province'] ?? '',
        city: json['city'] ?? '',
        district: json['district'] ?? '',
        detail: json['detail'] ?? '',
        isDefault: false,
        createdAt: '',
        updatedAt: '',
      );
    }
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