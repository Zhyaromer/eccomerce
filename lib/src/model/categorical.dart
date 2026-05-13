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
}
