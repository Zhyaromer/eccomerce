enum CategoricalType { small, medium, large }

class Categorical {
  CategoricalType categorical;
  bool isSelected = false;
  int? price;
  int? stock;

  Categorical(
    this.categorical,
    this.isSelected, {
    this.price,
    this.stock,
  });

  factory Categorical.fromMap(Map<String, dynamic> map) {
    return Categorical(
      CategoricalType.values.firstWhere(
        (type) => type.name == map['value'],
        orElse: () => CategoricalType.small,
      ),
      map['isSelected'] as bool? ?? false,
      price: (map['price'] as num?)?.toInt(),
      stock: (map['stock'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': categorical.name,
      'isSelected': isSelected,
      'price': price,
      'stock': stock,
    };
  }
}
