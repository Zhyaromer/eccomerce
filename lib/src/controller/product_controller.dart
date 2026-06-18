import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:e_commerce_flutter/core/app_data.dart';
import 'package:e_commerce_flutter/src/model/cart_item.dart';
import 'package:e_commerce_flutter/src/model/product.dart';
import 'package:e_commerce_flutter/src/model/numerical.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:e_commerce_flutter/src/model/product_category.dart';
import 'package:e_commerce_flutter/src/model/product_size_type.dart';

class ProductController extends GetxController {
  List<Product> allProducts = [];
  RxList<Product> filteredProducts = <Product>[].obs;
  RxList<CartItem> cartProducts = <CartItem>[].obs;
  RxList<ProductCategory> categories = <ProductCategory>[
    ProductCategory.all(),
  ].obs;
  RxInt totalPrice = 0.obs;
  String _searchQuery = '';
  String _selectedCategoryId = 'all';
  bool _showingFavorites = false;
  bool isLoadingProducts = false;
  String? productsError;
  bool _productsLoadedFromFirestore = false;

  String _productDocumentId(Product product) {
    final normalizedName = product.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return normalizedName.isEmpty ? product.name : normalizedName;
  }

  String _favoriteDocumentId(Product product) {
    return product.id ?? _productDocumentId(product);
  }

  CollectionReference<Map<String, dynamic>>? get _favoriteCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites');
  }

  Future<void> fetchCategoriesFromFirestore() async {
    final selectedCategoryId = _selectedCategoryId;

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aName = a.data()['name']?.toString() ?? a.id;
          final bName = b.data()['name']?.toString() ?? b.id;
          return aName.compareTo(bName);
        });

      final loadedCategories = docs
          .map(
            (doc) => ProductCategory.fromMap(
              doc.id,
              doc.data(),
              isSelected: doc.id == selectedCategoryId,
            ),
          )
          .toList();

      final productCategories = allProducts
          .map((product) => product.category)
          .where((category) => category.isNotEmpty)
          .where(
            (category) =>
                loadedCategories.every((item) => item.id != category),
          )
          .map(
            (category) => ProductCategory(
              id: category,
              name: category,
              isSelected: category == selectedCategoryId,
            ),
          );

      final nextCategories = [
        ProductCategory.all()..isSelected = selectedCategoryId == 'all',
        ...loadedCategories,
        ...productCategories,
      ];

      categories.assignAll(nextCategories);
    } on FirebaseException {
      categories.assignAll(
        AppData.categories.map((category) {
          category.isSelected = category.id == selectedCategoryId;
          return category;
        }),
      );
    }
  }

  Future<void> syncFavoritesFromFirestore() async {
    final favoriteCollection = _favoriteCollection;
    if (favoriteCollection == null) return;

    final snapshot = await favoriteCollection.get();
    final favoriteIds = snapshot.docs
        .map((doc) => doc.data()['productId'] as String?)
        .whereType<String>()
        .toSet();
    final favoriteNames = snapshot.docs
        .map((doc) => doc.data()['productName'] as String?)
        .whereType<String>()
        .toSet();

    for (final product in allProducts) {
      product.isFavorite = favoriteIds.contains(product.id) ||
          favoriteNames.contains(product.name);
    }
  }

  Future<void> fetchProductsFromFirestore({bool forceRefresh = false}) async {
    if (_productsLoadedFromFirestore && !forceRefresh) return;

    isLoadingProducts = true;
    productsError = null;
    update();

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aOrder = a.data()['sortOrder'] as int?;
          final bOrder = b.data()['sortOrder'] as int?;

          if (aOrder != null && bOrder != null) {
            return aOrder.compareTo(bOrder);
          }

          return a.id.compareTo(b.id);
        });

      allProducts =
          docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
      filteredProducts.assignAll(allProducts);
      _productsLoadedFromFirestore = true;
    } on FirebaseException catch (error) {
      allProducts = [];
      filteredProducts.clear();
      _productsLoadedFromFirestore = false;
      productsError = error.message ?? 'Could not load products.';
    } finally {
      isLoadingProducts = false;
      update();
    }
  }

  void filterItemsByCategory(int index) {
    _showingFavorites = false;
    for (ProductCategory element in categories) {
      element.isSelected = false;
    }
    categories[index].isSelected = true;
    _selectedCategoryId = categories[index].id;
    _applyFilters();
  }

  void searchProducts(String query) {
    _showingFavorites = false;
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    filteredProducts.assignAll(allProducts.where((item) {
      final matchesCategory =
          _selectedCategoryId == 'all' || item.category == _selectedCategoryId;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery) ||
          item.category.toLowerCase().contains(_searchQuery) ||
          item.type.name.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList());
    update();
  }

  Future<void> isFavorite(int index) async {
    final product = filteredProducts[index];
    product.isFavorite = !product.isFavorite;
    update();

    final favoriteCollection = _favoriteCollection;
    if (favoriteCollection != null) {
      final favoriteDoc = favoriteCollection.doc(_favoriteDocumentId(product));
      if (product.isFavorite) {
        await favoriteDoc.set({
          'productId': product.id ?? _productDocumentId(product),
          'productName': product.name,
          'productType': product.category,
          'price': product.price,
          'off': product.off,
          'imagePath': product.images.isNotEmpty ? product.images[0] : null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await favoriteDoc.delete();
      }
    }

    if (_showingFavorites) {
      filteredProducts.assignAll(
        allProducts.where((item) => item.isFavorite),
      );
      update();
    }
  }

  bool addToCart(Product product, {int quantity = 1}) {
    final selectedSize = selectedSizeLabel(product);
    final selectedStock = selectedVariantStock(product);
    final currentVariantQuantity = quantityForVariant(product, selectedSize);
    final usesVariantStock = selectedSize != 'Default';

    if (!product.isAvailable ||
        selectedStock == 0 ||
        currentVariantQuantity + quantity > selectedStock ||
        (!usesVariantStock && product.quantity + quantity > product.stock)) {
      return false;
    }

    CartItem? existingItem;
    for (final item in cartProducts) {
      if (item.matches(product, selectedSize)) {
        existingItem = item;
        break;
      }
    }

    product.quantity += quantity;
    if (existingItem == null) {
      cartProducts.add(
        CartItem(
          product: product,
          sizeLabel: selectedSize,
          unitPrice: selectedVariantPrice(product),
          originalUnitPrice: selectedVariantOriginalPrice(product),
          stockLimit: selectedStock,
          quantity: quantity,
        ),
      );
    } else {
      existingItem.quantity += quantity;
      cartProducts.refresh();
    }

    calculateTotalPrice();
    update();
    return true;
  }

  bool increaseItemQuantity(CartItem item) {
    if (item.quantity >= item.stockLimit) {
      return false;
    }

    item.product.quantity++;
    item.quantity++;
    cartProducts.refresh();
    calculateTotalPrice();
    update();
    return true;
  }

  void decreaseItemQuantity(CartItem item) {
    item.product.quantity--;
    item.quantity--;
    if (item.quantity == 0) {
      cartProducts.remove(item);
    } else {
      cartProducts.refresh();
    }
    calculateTotalPrice();
    update();
  }

  bool hasDiscount(Product product) {
    return product.off != null && product.off! > 0;
  }

  bool isPriceOff(Product product) => hasDiscount(product);

  int discountedPriceFor(Product product, int price) {
    if (!hasDiscount(product)) return price;

    final discountedPrice = price - product.off!;
    return discountedPrice < 0 ? 0 : discountedPrice;
  }

  int productDisplayPrice(Product product) {
    return discountedPriceFor(product, product.price);
  }

  int? productOriginalPrice(Product product) {
    return hasDiscount(product) ? product.price : null;
  }

  bool get isEmptyCart => cartProducts.isEmpty;

  int get cartItemCount {
    return cartProducts.fold(0, (sum, item) => sum + item.quantity);
  }

  int quantityForVariant(Product product, String sizeLabel) {
    return cartProducts
        .where((item) => item.matches(product, sizeLabel))
        .fold(0, (sum, item) => sum + item.quantity);
  }

  bool isNominal(Product product) => product.sizes?.numerical != null;

  void calculateTotalPrice() {
    totalPrice.value = 0;
    for (var element in cartProducts) {
      totalPrice.value += element.lineTotal;
    }
  }

  Future<void> getFavoriteItems() async {
    _showingFavorites = true;
    await fetchProductsFromFirestore();
    await syncFavoritesFromFirestore();
    filteredProducts.assignAll(
      allProducts.where((item) => item.isFavorite),
    );
    update();
  }

  getCartItems() {
    cartProducts.refresh();
  }

  Future<void> showFavoriteItems() async {
    await getFavoriteItems();
  }

  void refreshCart() {
    calculateTotalPrice();
    update();
  }

  void clearCart() {
    for (final item in cartProducts) {
      item.product.quantity = 0;
    }
    cartProducts.clear();
    calculateTotalPrice();
    update();
  }

  Future<void> getAllItems() async {
    _showingFavorites = false;
    await fetchProductsFromFirestore();
    await fetchCategoriesFromFirestore();
    await syncFavoritesFromFirestore();
    _searchQuery = '';
    _selectedCategoryId = 'all';
    for (ProductCategory element in categories) {
      element.isSelected = element.id == 'all';
    }
    _applyFilters();
  }

  List<Numerical> sizeType(Product product) {
    ProductSizeType? productSize = product.sizes;
    List<Numerical> numericalList = [];

    if (productSize?.numerical != null) {
      for (var element in productSize!.numerical!) {
        numericalList.add(
          Numerical(
            element.numerical,
            element.isSelected,
            price: element.price,
            stock: element.stock,
          ),
        );
      }
    }

    if (productSize?.categorical != null) {
      for (var element in productSize!.categorical!) {
        numericalList.add(
          Numerical(
            element.categorical.name,
            element.isSelected,
            price: element.price,
            stock: element.stock,
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

  String selectedSizeLabel(Product product) {
    final currentSize = getCurrentSize(product);
    return currentSize.isEmpty
        ? 'Default'
        : currentSize.replaceFirst('Size: ', '');
  }

  int? _selectedVariantRawPrice(Product product) {
    if (product.sizes?.categorical != null) {
      for (final element in product.sizes!.categorical!) {
        if (element.isSelected) {
          return element.price;
        }
      }
    }

    if (product.sizes?.numerical != null) {
      for (final element in product.sizes!.numerical!) {
        if (element.isSelected) {
          return element.price;
        }
      }
    }

    return null;
  }

  int selectedVariantPrice(Product product) {
    return discountedPriceFor(
      product,
      _selectedVariantRawPrice(product) ?? product.price,
    );
  }

  int? selectedVariantOriginalPrice(Product product) {
    if (!hasDiscount(product)) return null;

    return _selectedVariantRawPrice(product) ?? product.price;
  }

  int selectedVariantStock(Product product) {
    if (product.sizes?.categorical != null) {
      for (final element in product.sizes!.categorical!) {
        if (element.isSelected) {
          return element.stock ?? product.stock;
        }
      }
    }

    if (product.sizes?.numerical != null) {
      for (final element in product.sizes!.numerical!) {
        if (element.isSelected) {
          return element.stock ?? product.stock;
        }
      }
    }

    return product.stock;
  }

  int selectedVariantRemainingStock(Product product) {
    final selectedSize = selectedSizeLabel(product);
    return selectedVariantStock(product) -
        quantityForVariant(product, selectedSize);
  }
}
