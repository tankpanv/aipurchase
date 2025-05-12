import 'product_model.dart';

class CartItem {
  final int? id;
  final int userId;
  final int productId;
  final int quantity;
  final bool selected;
  final ProductSimple? product;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItem({
    this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.selected = true,
    this.product,
    this.createdAt,
    this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    ProductSimple? product;
    if (json['product'] != null) {
      final Map<String, dynamic> productJson = Map<String, dynamic>.from(json['product']);
      if (productJson['merchant'] != null) {
        productJson['merchant_id'] = productJson['merchant']['id'];
        productJson['merchant_name'] = productJson['merchant']['name'];
      }
      product = ProductSimple.fromJson(productJson);
    }

    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'] ?? 1,
      selected: json['selected'] ?? true,
      product: product,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'selected': selected,
      'product': product?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CartItem copyWith({
    int? id,
    int? userId,
    int? productId,
    int? quantity,
    bool? selected,
    ProductSimple? product,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      selected: selected ?? this.selected,
      product: product ?? this.product,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalPrice => (product?.price ?? 0) * quantity;
  
  String get productName => product?.name ?? '';
  
  String? get productImage => product?.mainImageUrl;
  
  double get price => product?.price ?? 0;
  
  String? get unit => product?.unit;
  
  String? get merchantName => product?.merchantName;
} 