import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:e_commerce_flutter/src/service/auth_destination.dart';
import 'package:e_commerce_flutter/src/view/screen/email_verification_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _finishSplash();
  }

  Future<void> _finishSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    final Widget nextScreen;
    if (refreshedUser == null) {
      nextScreen = const WelcomeScreen();
    } else if (refreshedUser.emailVerified) {
      nextScreen = await AuthDestination.forSignedInUser(refreshedUser);
    } else {
      nextScreen = const EmailVerificationScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 120),
              const SizedBox(height: 22),
              const Text(
                "Ibrahim Ahmed Shop",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Smart shopping starts here",
                style: TextStyle(
                  color: AppColor.darkOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
