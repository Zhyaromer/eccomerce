import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_flutter/src/controller/product_controller.dart';
import 'package:e_commerce_flutter/src/view/screen/home_screen.dart';
import 'package:e_commerce_flutter/src/view/animation/animated_switcher_wrapper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ProductController controller = Get.put(ProductController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoadingProfile = true;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    _emailController.text = user.email ?? '';
    _nameController.text = user.displayName ?? '';
    _cardHolderController.text = _nameController.text;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data();
      if (data != null) {
        _nameController.text =
            data['fullName'] as String? ?? _nameController.text;
        _emailController.text =
            data['email'] as String? ?? _emailController.text;
        _phoneController.text = data['phone'] as String? ?? '';
        _addressController.text = data['address'] as String? ?? '';
        _cardHolderController.text = _nameController.text;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  String? _cardNumberValidator(String? value) {
    final cardNumber = value?.trim() ?? '';
    if (cardNumber.length != 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _cardHolderValidator(String? value) {
    final cardHolder = value?.trim() ?? '';
    if (cardHolder.length < 3) {
      return 'Enter the cardholder name';
    }

    final validName = RegExp(r"^[a-zA-Z\s'.-]+$").hasMatch(cardHolder);
    if (!validName) {
      return 'Use letters only';
    }

    return null;
  }

  String? _expiryValidator(String? value) {
    final expiry = value?.trim() ?? '';
    final match = RegExp(r'^(0[1-9]|1[0-2])(\d{2})$').firstMatch(expiry);
    if (match == null) {
      return 'Use MMYY';
    }

    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final now = DateTime.now();
    final lastDayOfExpiryMonth = DateTime(year, month + 1, 0);

    if (lastDayOfExpiryMonth.isBefore(DateTime(now.year, now.month, 1))) {
      return 'Card is expired';
    }

    return null;
  }

  String? _cvvValidator(String? value) {
    final cvv = value?.trim() ?? '';
    if (cvv.length < 3 || cvv.length > 4) {
      return 'Use 3 or 4 digits';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^(07\d{9}|7\d{9})$').hasMatch(phone)) {
      return 'Use an Iraqi phone number, like 07701234567';
    }
    return null;
  }

  String? _addressValidator(String? value) {
    final address = value?.trim() ?? '';
    if (address.length < 10) {
      return 'Enter a complete address';
    }
    return null;
  }

  Future<void> _submitCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _savePurchaseAndReduceStock().timeout(
        const Duration(seconds: 20),
      );
      await Future.delayed(const Duration(seconds: 3));
      await controller.fetchProductsFromFirestore(forceRefresh: true).timeout(
            const Duration(seconds: 20),
          );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showCheckoutError(error.message ?? 'Could not save purchase.');
      return;
    } on TimeoutException {
      if (!mounted) return;
      _showCheckoutError(
        'Checkout took too long. Check your connection and Firestore rules.',
      );
      return;
    } catch (error) {
      if (!mounted) return;
      _showCheckoutError('Checkout failed: $error');
      return;
    }

    controller.clearCart();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });
  }

  void _showCheckoutError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        content: Text(message),
      ),
    );
  }

  Future<void> _savePurchaseAndReduceStock() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Please sign in before checkout.',
      );
    }

    final cartItems = controller.cartProducts.toList();
    final items = cartItems.map((item) {
      return {
        'productId': item.product.id,
        'productName': item.product.name,
        'sizeLabel': item.sizeLabel,
        'unitPrice': item.unitPrice,
        'quantity': item.quantity,
        'lineTotal': item.lineTotal,
        'imagePath':
            item.product.images.isEmpty ? null : item.product.images.first,
      };
    }).toList();

    if (items.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Your cart is empty.',
      );
    }

    final firestore = FirebaseFirestore.instance;
    for (final item in cartItems) {
      final productId = item.product.id;
      if (productId == null || productId.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Missing product id for ${item.product.name}.',
        );
      }
    }

    final productIds = cartItems.map((item) => item.product.id!).toSet();
    final productSnapshots =
        <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final productId in productIds) {
      final productRef = firestore.collection('products').doc(productId);
      productSnapshots[productId] = await productRef.get();
    }

    final batch = firestore.batch();
    for (final productId in productIds) {
      final productRef = firestore.collection('products').doc(productId);
      final productSnapshot = productSnapshots[productId]!;
      final productData = productSnapshot.data();
      final productItems =
          cartItems.where((item) => item.product.id == productId).toList();
      final productName = productItems.first.product.name;
      final purchasedQuantity = productItems.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      if (!productSnapshot.exists || productData == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: '$productName is no longer available.',
        );
      }

      final stock = productData['stock'] as int? ?? 0;
      if (stock < purchasedQuantity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Not enough stock for $productName.',
        );
      }

      final updatedData = Map<String, dynamic>.from(productData);
      updatedData['stock'] = stock - purchasedQuantity;
      updatedData['isAvailable'] = updatedData['stock'] > 0;

      final sizes = productData['sizes'];
      if (sizes is Map<String, dynamic>) {
        var updatedSizes = sizes;
        for (final item in productItems) {
          if (item.sizeLabel == 'Default') continue;

          final reducedSizes = _reduceVariantStock(
            updatedSizes,
            item.sizeLabel,
            item.quantity,
          );
          if (reducedSizes == null) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              message:
                  'Not enough stock for ${item.product.name} size ${item.sizeLabel}.',
            );
          }

          updatedSizes = reducedSizes;
        }
        updatedData['sizes'] = updatedSizes;
      }

      batch.update(productRef, updatedData);
    }

    final purchaseRef = firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchases')
        .doc();

    batch.set(
      firestore.collection('users').doc(user.uid),
      {
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(purchaseRef, {
      'items': items,
      'total': controller.totalPrice.value,
      'customerName': _nameController.text.trim(),
      'customerEmail': _emailController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'deliveryAddress': _addressController.text.trim(),
      'cardHolder': _cardHolderController.text.trim(),
      'status': 'Purchased',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Map<String, dynamic>? _reduceVariantStock(
    Map<String, dynamic> sizes,
    String sizeLabel,
    int quantity,
  ) {
    final updatedSizes = Map<String, dynamic>.from(sizes);
    final listKey = updatedSizes.containsKey('numerical')
        ? 'numerical'
        : updatedSizes.containsKey('categorical')
            ? 'categorical'
            : null;

    if (listKey == null) return updatedSizes;

    final rawVariants = updatedSizes[listKey];
    if (rawVariants is! List<dynamic>) {
      return null;
    }

    final variants = rawVariants
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final variantIndex = variants.indexWhere(
      (variant) => variant['value'] == sizeLabel,
    );

    if (variantIndex == -1) return updatedSizes;

    final variant = variants[variantIndex];
    final stock = variant['stock'] as int? ?? 0;
    if (stock < quantity) {
      return null;
    }

    variant['stock'] = stock - quantity;
    variants[variantIndex] = variant;
    updatedSizes[listKey] = variants;
    return updatedSizes;
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    required String hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _checkoutForm() {
    if (_isLoadingProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: Color(0xFFEC6813),
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Checkout',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              'Total: \$${controller.totalPrice.value}',
              style: const TextStyle(
                color: Color(0xFFEC6813),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            enabled: false,
            decoration: _inputDecoration(
              'Full name',
              Icons.person,
              hintText: 'Your name',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailController,
            enabled: false,
            decoration: _inputDecoration(
              'Email',
              Icons.email_outlined,
              hintText: 'your@email.com',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: _phoneValidator,
            decoration: _inputDecoration(
              'Phone number',
              Icons.phone_outlined,
              hintText: '07701234567',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _addressController,
            minLines: 3,
            maxLines: 4,
            validator: _addressValidator,
            decoration: _inputDecoration(
              'Delivery address',
              Icons.home,
              hintText: 'Street, city, building, apartment',
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            validator: _cardNumberValidator,
            decoration: _inputDecoration(
              'Card number',
              Icons.credit_card,
              hintText: '4242424242424242',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cardHolderController,
            textCapitalization: TextCapitalization.words,
            validator: _cardHolderValidator,
            decoration: _inputDecoration(
              'Cardholder name',
              Icons.person,
              hintText: 'Ibrahim Ahmed',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: _expiryValidator,
                  decoration: _inputDecoration(
                    'Expiry date',
                    Icons.calendar_month,
                    hintText: 'MMYY',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: _cvvValidator,
                  decoration: _inputDecoration(
                    'CVV',
                    Icons.lock,
                    hintText: '123',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitCheckout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(18),
            ),
            child: AnimatedSwitcherWrapper(
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Checkout',
                      key: ValueKey('checkout'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          child: Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF23814D),
              size: 52,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Purchase succeeded',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your cart has been cleared.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(18),
          ),
          child: const Text(
            'Back to shopping',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text(
          'Payment',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcherWrapper(
                child: _isSuccess ? _successState() : _checkoutForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
