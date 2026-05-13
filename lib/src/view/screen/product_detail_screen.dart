import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:e_commerce_flutter/src/model/product.dart';
import 'package:e_commerce_flutter/src/view/widget/carousel_slider.dart';
import 'package:e_commerce_flutter/src/controller/product_controller.dart';

final ProductController controller = Get.put(ProductController());

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen(this.product, {super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  Product get product => widget.product;

  void _clampQuantityToStock() {
    final remainingStock = controller.selectedVariantRemainingStock(product);
    if (remainingStock <= 0) {
      _quantity = 1;
      return;
    }

    if (_quantity > remainingStock) {
      _quantity = remainingStock;
    }

    if (_quantity < 1) {
      _quantity = 1;
    }
  }

  void _increaseQuantity() {
    final remainingStock = controller.selectedVariantRemainingStock(product);
    if (remainingStock <= 0 || _quantity >= remainingStock) return;

    setState(() => _quantity++);
  }

  void _decreaseQuantity() {
    if (_quantity <= 1) return;

    setState(() => _quantity--);
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.black),
      ),
    );
  }

  Widget productPageView(double width, double height) {
    return Container(
      height: height * 0.42,
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F2F4),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(80),
          bottomLeft: Radius.circular(80),
        ),
      ),
      child: CarouselSlider(items: product.images),
    );
  }

  Widget productSizesListView() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: controller.sizeType(product).length,
      itemBuilder: (_, index) {
        final size = controller.sizeType(product)[index];
        return InkWell(
          onTap: () {
            controller.switchBetweenProductSizes(product, index);
            setState(_clampQuantityToStock);
          },
          child: AnimatedContainer(
            margin: const EdgeInsets.only(right: 5, left: 5),
            alignment: Alignment.center,
            width: controller.isNominal(product) ? 56 : 82,
            decoration: BoxDecoration(
              color: size.isSelected == false
                  ? Colors.white
                  : AppColor.lightOrange,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey,
                width: 0.4,
              ),
            ),
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  size.numerical,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (size.price != null)
                  Text(
                    "\$${size.price}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quantitySelector() {
    return GetBuilder<ProductController>(
      builder: (_) {
        final remainingStock =
            controller.selectedVariantRemainingStock(product);
        final hasStock = product.isAvailable && remainingStock > 0;
        final visibleQuantity = hasStock ? _quantity : 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quantity",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed:
                          hasStock && _quantity > 1 ? _decreaseQuantity : null,
                      icon: const Icon(Icons.remove_rounded),
                      color: AppColor.darkOrange,
                    ),
                    SizedBox(
                      width: 38,
                      child: Text(
                        "$visibleQuantity",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: hasStock ? Colors.black : Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: hasStock && _quantity < remainingStock
                          ? _increaseQuantity
                          : null,
                      icon: const Icon(Icons.add_rounded),
                      color: AppColor.darkOrange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _appBar(context),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  productPageView(width, height),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            GetBuilder<ProductController>(
                              builder: (_) {
                                return Text(
                                  "\$${controller.selectedVariantPrice(
                                    product,
                                  )}",
                                  style:
                                      Theme.of(context).textTheme.displayLarge,
                                );
                              },
                            ),
                            const SizedBox(width: 3),
                            Visibility(
                              visible: product.off != null ? true : false,
                              child: Text(
                                "\$${product.price}",
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.red,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            GetBuilder<ProductController>(
                              builder: (_) {
                                final remainingStock =
                                    controller.selectedVariantRemainingStock(
                                  product,
                                );
                                final hasStock =
                                    product.isAvailable && remainingStock > 0;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: hasStock
                                        ? const Color(0xFFEAF7EF)
                                        : const Color(0xFFFFECEC),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    hasStock
                                        ? "$remainingStock in stock"
                                        : "Out of stock",
                                    style: TextStyle(
                                      color: hasStock
                                          ? const Color(0xFF23814D)
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text(
                          "About",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(product.about),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 56,
                          child: GetBuilder<ProductController>(
                            builder: (_) => productSizesListView(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _quantitySelector(),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: GetBuilder<ProductController>(
                            builder: (_) {
                              final remainingStock =
                                  controller.selectedVariantRemainingStock(
                                product,
                              );
                              final canAdd = product.isAvailable &&
                                  remainingStock > 0 &&
                                  _quantity <= remainingStock;
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                ),
                                onPressed: canAdd
                                    ? () {
                                        final selectedQuantity = _quantity;
                                        final wasAdded = controller.addToCart(
                                          product,
                                          quantity: selectedQuantity,
                                        );
                                        setState(_clampQuantityToStock);
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: wasAdded
                                                ? const Color(0xFF1F7A4D)
                                                : Colors.redAccent,
                                            content: Text(
                                              wasAdded
                                                  ? "$selectedQuantity x ${product.name} "
                                                      "(${controller.selectedSizeLabel(product)}) added to cart"
                                                  : "No more stock available for ${product.name}",
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(
                                  canAdd ? "Add to cart" : "Out of stock",
                                  style: TextStyle(
                                    color: canAdd
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
