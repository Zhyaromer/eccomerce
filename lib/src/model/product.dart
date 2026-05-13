import 'package:e_commerce_flutter/core/app_data.dart';
import 'package:e_commerce_flutter/src/model/product_size_type.dart';

enum ProductType { all, watch, mobile, headphone, tablet, tv }

class Product {
  String? id;
  String name;
  int price;
  int? off;
  String about;
  bool isAvailable;
  int stock;
  ProductSizeType? sizes;
  int _quantity;
  List<String> images;
  bool isFavorite;
  double rating;
  ProductType type;

  int get quantity => _quantity;

  set quantity(int newQuantity) {
    if (newQuantity >= 0 && newQuantity <= stock) _quantity = newQuantity;
  }

  int get remainingStock => stock - _quantity;

  Product({
    this.id,
    this.sizes,
    this.about = AppData.dummyText,
    required this.name,
    required this.price,
    required this.isAvailable,
    required this.stock,
    required this.off,
    required int quantity,
    required this.images,
    required this.isFavorite,
    required this.rating,
    required this.type,
  }) : _quantity = quantity;

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      price: map['price'] as int? ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? false,
      stock: map['stock'] as int? ?? 0,
      off: map['off'] as int?,
      quantity: 0,
      images: (map['images'] as List<dynamic>?)?.cast<String>() ?? [],
      isFavorite: false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      about: map['about'] as String? ?? AppData.dummyText,
      sizes: map['sizes'] == null
          ? null
          : ProductSizeType.fromMap(
              Map<String, dynamic>.from(map['sizes'] as Map),
            ),
      type: ProductType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => ProductType.mobile,
      ),
    );
  }

  Map<String, dynamic> toMap({int? sortOrder}) {
    return {
      'name': name,
      'price': price,
      'off': off,
      'about': about,
      'isAvailable': isAvailable,
      'stock': stock,
      'images': images,
      'rating': rating,
      'type': type.name,
      if (sizes != null) 'sizes': sizes!.toMap(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }
}
