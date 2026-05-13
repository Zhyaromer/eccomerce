class Numerical {
  String numerical;
  bool isSelected = false;
  int? price;
  int? stock;

  Numerical(
    this.numerical,
    this.isSelected, {
    this.price,
    this.stock,
  });

  factory Numerical.fromMap(Map<String, dynamic> map) {
    return Numerical(
      map['value'] as String? ?? '',
      map['isSelected'] as bool? ?? false,
      price: map['price'] as int?,
      stock: map['stock'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': numerical,
      'isSelected': isSelected,
      'price': price,
      'stock': stock,
    };
  }
}
