import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:e_commerce_flutter/core/app_data.dart';
import 'package:e_commerce_flutter/src/model/product.dart';
import 'package:e_commerce_flutter/src/model/numerical.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:e_commerce_flutter/src/model/product_category.dart';
import 'package:e_commerce_flutter/src/model/product_size_type.dart';

class ProductController extends GetxController {
  List<Product> allProducts = AppData.products;
  RxList<Product> filteredProducts = AppData.products.obs;
  RxList<Product> cartProducts = <Product>[].obs;
  RxList<ProductCategory> categories = AppData.categories.obs;
  RxInt totalPrice = 0.obs;
  String _searchQuery = '';
  ProductType _selectedType = ProductType.all;

  void filterItemsByCategory(int index) {
    for (ProductCategory element in categories) {
      element.isSelected = false;
    }
    categories[index].isSelected = true;
    _selectedType = categories[index].type;
    _applyFilters();
  }

  void searchProducts(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    filteredProducts.assignAll(allProducts.where((item) {
      final matchesCategory =
          _selectedType == ProductType.all || item.type == _selectedType;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery) ||
          item.type.name.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList());
    update();
  }

  void isFavorite(int index) {
    filteredProducts[index].isFavorite = !filteredProducts[index].isFavorite;
    update();
  }

  bool addToCart(Product product) {
    if (!product.isAvailable ||
        product.stock == 0 ||
        product.quantity >= product.stock) {
      return false;
    }

    product.quantity++;
    getCartItems();
    calculateTotalPrice();
    update();
    return true;
  }

  bool increaseItemQuantity(Product product) {
    if (product.quantity >= product.stock) {
      return false;
    }

    product.quantity++;
    calculateTotalPrice();
    update();
    return true;
  }

  void decreaseItemQuantity(Product product) {
    product.quantity--;
    if (product.quantity == 0) {
      cartProducts.remove(product);
    }
    calculateTotalPrice();
    update();
  }

  bool isPriceOff(Product product) => product.off != null;

  bool get isEmptyCart => cartProducts.isEmpty;

  bool isNominal(Product product) => product.sizes?.numerical != null;

  void calculateTotalPrice() {
    totalPrice.value = 0;
    for (var element in cartProducts) {
      if (isPriceOff(element)) {
        totalPrice.value += element.quantity * element.off!;
      } else {
        totalPrice.value += element.quantity * element.price;
      }
    }
  }

  getFavoriteItems() {
    filteredProducts.assignAll(
      allProducts.where((item) => item.isFavorite),
    );
  }

  getCartItems() {
    cartProducts.assignAll(
      allProducts.where((item) => item.quantity > 0),
    );
  }

  void showFavoriteItems() {
    getFavoriteItems();
    update();
  }

  void refreshCart() {
    getCartItems();
    calculateTotalPrice();
    update();
  }

  getAllItems() {
    _searchQuery = '';
    _selectedType = ProductType.all;
    for (ProductCategory element in categories) {
      element.isSelected = element.type == ProductType.all;
    }
    _applyFilters();
  }

  List<Numerical> sizeType(Product product) {
    ProductSizeType? productSize = product.sizes;
    List<Numerical> numericalList = [];

    if (productSize?.numerical != null) {
      for (var element in productSize!.numerical!) {
        numericalList.add(Numerical(element.numerical, element.isSelected));
      }
    }

    if (productSize?.categorical != null) {
      for (var element in productSize!.categorical!) {
        numericalList.add(
          Numerical(
            element.categorical.name,
            element.isSelected,
          ),
        );
      }
    }

    return numericalList;
  }

  void switchBetweenProductSizes(Product product, int index) {
    sizeType(product).forEach((element) {
      element.isSelected = false;
    });

    if (product.sizes?.categorical != null) {
      for (var element in product.sizes!.categorical!) {
        element.isSelected = false;
      }

      product.sizes?.categorical![index].isSelected = true;
    }

    if (product.sizes?.numerical != null) {
      for (var element in product.sizes!.numerical!) {
        element.isSelected = false;
      }

      product.sizes?.numerical![index].isSelected = true;
    }

    update();
  }

  String getCurrentSize(Product product) {
    String currentSize = "";
    if (product.sizes?.categorical != null) {
      for (var element in product.sizes!.categorical!) {
        if (element.isSelected) {
          currentSize = "Size: ${element.categorical.name}";
        }
      }
    }

    if (product.sizes?.numerical != null) {
      for (var element in product.sizes!.numerical!) {
        if (element.isSelected) {
          currentSize = "Size: ${element.numerical}";
        }
      }
    }
    return currentSize;
  }
}
