import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:e_commerce_flutter/src/view/screen/auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openAuth(BuildContext context, AuthMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuthScreen(initialMode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Image.asset(
                    'assets/images/shopping.png',
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Welcome to Ibrahim Ahmed Shop",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sign in to continue shopping, tracking orders, and saving your favorite products.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _openAuth(context, AuthMode.signIn),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                    ),
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _openAuth(context, AuthMode.signUp),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.darkOrange,
                      side: const BorderSide(color: AppColor.darkOrange),
                      padding: const EdgeInsets.all(18),
                    ),
                    child: const Text(
                      "Create account",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
