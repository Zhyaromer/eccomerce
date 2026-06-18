class ProductCategory {
  String id;
  String name;
  bool isSelected;

  ProductCategory({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  factory ProductCategory.all() {
    return ProductCategory(
      id: 'all',
      name: 'All',
      isSelected: true,
    );
  }

  factory ProductCategory.fromMap(
    String id,
    Map<String, dynamic> data, {
    bool isSelected = false,
  }) {
    return ProductCategory(
      id: id,
      name: data['name']?.toString() ?? id,
      isSelected: isSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
