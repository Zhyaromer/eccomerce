import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/extensions.dart';
import 'package:e_commerce_flutter/src/model/cart_item.dart';
import 'package:e_commerce_flutter/src/model/product.dart';
import 'package:e_commerce_flutter/src/view/widget/empty_cart.dart';
import 'package:e_commerce_flutter/src/controller/product_controller.dart';
import 'package:e_commerce_flutter/src/view/screen/checkout_screen.dart';
import 'package:e_commerce_flutter/src/view/animation/animated_switcher_wrapper.dart';

final ProductController controller = Get.put(ProductController());

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        "Cart",
        style: Theme.of(context).textTheme.displayLarge,
      ),
    );
  }

  Widget cartList(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: controller.cartProducts.mapWithIndex((index, _) {
          CartItem cartItem = controller.cartProducts[index];
          Product product = cartItem.product;
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              spacing: 5,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: ColorExtension.randomColor,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.network(
                            product.images.isNotEmpty ? product.images[0] : '',
                            width: 100,
                            height: 90,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name.nextLine,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Size: ${cartItem.sizeLabel}",
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${cartItem.stockLimit - cartItem.quantity} left",
                        style: const TextStyle(
                          color: Color(0xFF23814D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "\$${cartItem.unitPrice}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 23,
                        ),
                      ),
                      if (cartItem.originalUnitPrice != null)
                        Text(
                          "\$${cartItem.originalUnitPrice}",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.red,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        splashRadius: 10.0,
                        onPressed: () =>
                            controller.decreaseItemQuantity(cartItem),
                        icon: const Icon(
                          Icons.remove,
                          color: Color(0xFFEC6813),
                        ),
                      ),
                      GetBuilder<ProductController>(
                        builder: (ProductController controller) {
                          return AnimatedSwitcherWrapper(
                            child: Text(
                              '${controller.cartProducts[index].quantity}',
                              key: ValueKey<int>(
                                controller.cartProducts[index].quantity,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        splashRadius: 10.0,
                        onPressed: () {
                          final didIncrease =
                              controller.increaseItemQuantity(cartItem);
                          if (!didIncrease) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  "Only ${product.stock} available for ${product.name}",
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add, color: Color(0xFFEC6813)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget bottomBarTitle() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEDEDED)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
          ),
          Obx(
            () {
              return AnimatedSwitcherWrapper(
                child: Text(
                  "\$${controller.totalPrice.value}",
                  key: ValueKey<int>(controller.totalPrice.value),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEC6813),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget bottomBarButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 30, right: 30, bottom: 20),
        child: GetBuilder<ProductController>(
          builder: (_) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
              onPressed: controller.isEmptyCart
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      );
                    },
              child: const Text(
                "Buy Now",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: _appBar(context),
      body: GetBuilder<ProductController>(
        builder: (_) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: !controller.isEmptyCart
                    ? cartList(context)
                    : const EmptyCart(),
              ),
              bottomBarTitle(),
              bottomBarButton(context)
            ],
          );
        },
      ),
    );
  }
}
