import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ProductSimple {
  final int id;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final String? mainImageUrl;
  final int merchantId;
  final String merchantName;
  final String productType;
  final bool isFeatured;
  final int stock;
  final String? unit;
  final String? discount;
  final String? createdAt;
  final String? publishedAt;
  final String? status;
  final List<Map<String, dynamic>>? categories;
  final List<String>? tags;
  final List<Map<String, dynamic>>? images;

  ProductSimple({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    this.mainImageUrl,
    required this.merchantId,
    required this.merchantName,
    required this.productType,
    required this.isFeatured,
    required this.stock,
    this.unit,
    this.discount = '',
    this.createdAt,
    this.publishedAt,
    this.status,
    this.categories,
    this.tags,
    this.images,
  });

  factory ProductSimple.fromJson(Map<String, dynamic> json) {
    // 价格处理函数
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    // 验证商品ID
    final id = json['id'];
    if (id == null) {
      throw const FormatException('商品ID不能为空');
    }

    return ProductSimple(
      id: id,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: parsePrice(json['price']),
      originalPrice: parsePrice(json['original_price']),
      mainImageUrl: json['main_image_url']?.toString(),
      merchantId: json['merchant_id'] ?? 0,
      merchantName: json['merchant_name']?.toString() ?? '',
      productType: json['product_type']?.toString() ?? 'general',
      isFeatured: json['is_featured'] ?? false,
      stock: (json['stock'] ?? 0) as int,
      unit: json['unit']?.toString(),
      discount: json['discount']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      publishedAt: json['published_at']?.toString(),
      status: json['status']?.toString(),
      categories: (json['categories'] as List?)?.map((e) => e as Map<String, dynamic>).toList(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      images: (json['images'] as List?)?.map((e) => e as Map<String, dynamic>).toList(),
    );
  }

  IconData getProductIcon() {
    switch (productType) {
      case 'takeout':
        return Icons.fastfood;
      case 'groupon':
        return Icons.group;
      case 'hotel':
        return Icons.hotel;
      case 'medicine':
        return Icons.medical_services;
      case 'fresh':
        return Icons.spa;
      case 'ticket':
        return Icons.movie;
      default:
        return Icons.shopping_basket;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'main_image_url': mainImageUrl,
      'merchant_id': merchantId,
      'merchant_name': merchantName,
      'product_type': productType,
      'is_featured': isFeatured,
      'stock': stock,
      'unit': unit,
      'discount': discount,
      'created_at': createdAt,
      'published_at': publishedAt,
    };
  }
}

class ProductsResponse {
  final int code;
  final String message;
  final List<ProductSimple> products;
  final int total;
  final int pages;
  final int currentPage;

  ProductsResponse({
    required this.code,
    required this.message,
    required this.products,
    required this.total,
    required this.pages,
    required this.currentPage,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    // 获取data对象
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      return ProductsResponse(
        code: json['code'] ?? 400,
        message: json['message'] ?? '请求失败',
        products: [],
        total: 0,
        pages: 1,
        currentPage: 1,
      );
    }

    List<ProductSimple> products = [];
    if (data['items'] != null) {
      for (var item in data['items']) {
        try {
          products.add(ProductSimple.fromJson(item));
        } catch (e) {
          debugPrint('解析商品数据失败: $e');
        }
      }
    }

    return ProductsResponse(
      code: json['code'] ?? 200,
      message: json['message'] ?? '请求失败',
      products: products,
      total: data['total'] ?? 0,
      pages: data['pages'] ?? 1,
      currentPage: data['current_page'] ?? 1,
    );
  }
} 