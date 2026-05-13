import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:e_commerce_flutter/src/model/product.dart';
import 'package:e_commerce_flutter/src/view/widget/carousel_slider.dart';
import 'package:e_commerce_flutter/src/controller/product_controller.dart';

final ProductController controller = Get.put(ProductController());

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen(this.product, {super.key});

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
        return InkWell(
          onTap: () => controller.switchBetweenProductSizes(product, index),
          child: AnimatedContainer(
            margin: const EdgeInsets.only(right: 5, left: 5),
            alignment: Alignment.center,
            width: controller.isNominal(product) ? 40 : 70,
            decoration: BoxDecoration(
              color: controller.sizeType(product)[index].isSelected == false
                  ? Colors.white
                  : AppColor.lightOrange,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey,
                width: 0.4,
              ),
            ),
            duration: const Duration(milliseconds: 300),
            child: FittedBox(
              child: Text(
                controller.sizeType(product)[index].numerical,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
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
                            Text(
                              product.off != null
                                  ? "\$${product.off}"
                                  : "\$${product.price}",
                              style: Theme.of(context).textTheme.displayLarge,
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
                                final hasStock = product.isAvailable &&
                                    product.remainingStock > 0;
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
                                        ? "${product.remainingStock} in stock"
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
                          height: 40,
                          child: GetBuilder<ProductController>(
                            builder: (_) => productSizesListView(),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: GetBuilder<ProductController>(
                            builder: (_) {
                              final canAdd = product.isAvailable &&
                                  product.remainingStock > 0;
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                ),
                                onPressed: canAdd
                                    ? () {
                                        final wasAdded =
                                            controller.addToCart(product);
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
                                                  ? "${product.name} added to cart"
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
                                    )),
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
