import 'package:flutter/material.dart';
import 'product_model.dart';

class ProductDetail extends ProductSimple {
  @override
  final List<Map<String, dynamic>>? images;
  @override
  final List<Map<String, dynamic>>? categories;
  @override
  final List<String>? tags;
  @override
  final String status;
  final String? spec;
  final List<String>? promotionTags;
  final Map<String, dynamic>? merchant;
  final DateTime? updatedAt;

  ProductDetail({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.originalPrice,
    super.mainImageUrl,
    required super.merchantId,
    required super.merchantName,
    required super.productType,
    required super.isFeatured,
    required super.stock,
    super.unit,
    super.discount = null,
    super.createdAt,
    super.publishedAt,
    this.images,
    this.categories,
    this.tags,
    this.status = 'published',
    this.spec,
    this.promotionTags,
    this.merchant,
    this.updatedAt,
  }) : super(
          status: status,
          categories: categories,
          tags: tags,
          images: images,
        );

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
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

    // 处理标签
    List<String> parseTags(List<dynamic>? tagsList) {
      if (tagsList == null) return [];
      return tagsList.map((tag) {
        if (tag is Map<String, dynamic>) {
          return tag['name']?.toString() ?? '';
        }
        return tag.toString();
      }).where((tag) => tag.isNotEmpty).toList();
    }

    return ProductDetail(
      id: data['id'],
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: parsePrice(data['price']),
      originalPrice: parsePrice(data['original_price']),
      mainImageUrl: data['main_image_url'],
      merchantId: data['merchant_id'] ?? 0,
      merchantName: data['merchant_name'] ?? '',
      productType: data['product_type'] ?? 'general',
      isFeatured: data['is_featured'] ?? false,
      stock: data['stock'] ?? 0,
      unit: data['unit'],
      discount: data['discount'] ?? '',
      createdAt: data['created_at'],
      publishedAt: data['published_at'],
      images: (data['images'] as List<dynamic>?)?.map((e) => {
        'url': e['url'] ?? e['image_url'],
        'is_main': e['is_main'] ?? false,
        'sort_order': e['sort_order'] ?? 0,
      }).toList(),
      categories: (data['categories'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      tags: parseTags(data['tags']),
      status: data['status'] ?? 'published',
      spec: data['spec'],
      promotionTags: (data['promotion_tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      merchant: data['merchant'] as Map<String, dynamic>?,
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data.addAll({
      'images': images,
      'categories': categories,
      'tags': tags,
      'status': status,
      'spec': spec,
      'promotion_tags': promotionTags,
      'merchant': merchant,
      'updated_at': updatedAt?.toIso8601String(),
    });
    return data;
  }
} 