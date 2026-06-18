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
  String category;

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
    String? category,
  })  : category = category ?? type.name,
        _quantity = quantity;

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    final images = (map['images'] as List<dynamic>?)
            ?.whereType<String>()
            .where((image) => image.trim().isNotEmpty)
            .toList() ??
        <String>[];
    for (final key in ['imageUrl', 'image', 'photoUrl', 'thumbnail']) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty && !images.contains(value)) {
        images.add(value);
      }
    }

    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? false,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      off: (map['off'] as num?)?.toInt(),
      quantity: 0,
      images: images,
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
      category: (map['category'] ?? map['type'] ?? ProductType.mobile.name)
          .toString(),
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
      'category': category,
      if (sizes != null) 'sizes': sizes!.toMap(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }
}
