import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _addressController.dispose();
    super.dispose();
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
    await Future.delayed(const Duration(seconds: 3));
    controller.clearCart();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });
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
