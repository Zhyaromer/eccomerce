import 'package:e_commerce_flutter/src/model/product.dart';

class CartItem {
  final Product product;
  final String sizeLabel;
  final int unitPrice;
  final int? originalUnitPrice;
  final int stockLimit;
  int quantity;

  CartItem({
    required this.product,
    required this.sizeLabel,
    required this.unitPrice,
    this.originalUnitPrice,
    required this.stockLimit,
    required this.quantity,
  });

  int get lineTotal => unitPrice * quantity;

  bool matches(Product otherProduct, String otherSizeLabel) {
    return identical(product, otherProduct) && sizeLabel == otherSizeLabel;
  }
}
