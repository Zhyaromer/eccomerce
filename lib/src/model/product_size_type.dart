import 'package:e_commerce_flutter/src/model/categorical.dart';
import 'package:e_commerce_flutter/src/model/numerical.dart';

class ProductSizeType {
  List<Numerical>? numerical;
  List<Categorical>? categorical;

  ProductSizeType({this.numerical, this.categorical});

  factory ProductSizeType.fromMap(Map<String, dynamic> map) {
    return ProductSizeType(
      numerical: (map['numerical'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(Numerical.fromMap)
          .toList(),
      categorical: (map['categorical'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(Categorical.fromMap)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (numerical != null)
        'numerical': numerical!.map((item) => item.toMap()).toList(),
      if (categorical != null)
        'categorical': categorical!.map((item) => item.toMap()).toList(),
    };
  }
}
