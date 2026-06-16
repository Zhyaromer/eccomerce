import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_flutter/src/service/auth_destination.dart';
import 'package:e_commerce_flutter/src/view/screen/email_verification_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/forgot_password_screen.dart';

enum AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.initialMode});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  late AuthMode _mode;
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get _isSignUp => _mode == AuthMode.signUp;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _isSignUp ? AuthMode.signIn : AuthMode.signUp;
      _formKey.currentState?.reset();
    });
  }

  String? _requiredNameValidator(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 3) {
      return 'Enter your full name';
    }

    if (!RegExp(r"^[a-zA-Z\s'.-]+$").hasMatch(name)) {
      return 'Use letters only';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'Enter a valid email';
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

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = credential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'missing-user',
            message: 'Could not create the user account.',
          );
        }

        await user.updateDisplayName(_fullNameController.text.trim());
        await user.sendEmailVerification();
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final credential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await credential.user?.reload();
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          content: Text(_authErrorMessage(error)),
        ),
      );
      return;
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          content: Text(error.message ?? 'Something went wrong.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    final user = _auth.currentUser;
    final destination = user == null
        ? const EmailVerificationScreen()
        : await AuthDestination.forSignedInUser(user);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (_) => false,
    );
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email already has an account.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: _passwordValidator,
      decoration: _inputDecoration(
        label: 'Password',
        hint: 'At least 6 characters',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isSignUp ? "Create account" : "Welcome back",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? "Create your profile to start shopping."
                          : "Sign in with your email and password.",
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        validator: _requiredNameValidator,
                        decoration: _inputDecoration(
                          label: 'Full name',
                          hint: 'Ibrahim Ahmed',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                      decoration: _inputDecoration(
                        label: 'Email',
                        hint: 'ibrahim@example.com',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: _phoneValidator,
                        decoration: _inputDecoration(
                          label: 'Phone number',
                          hint: '07701234567',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _passwordField(),
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                    if (_isSignUp) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        minLines: 3,
                        maxLines: 4,
                        validator: _addressValidator,
                        decoration: _inputDecoration(
                          label: 'Address',
                          hint: 'Baghdad, street, building, apartment',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text(
                              _isSignUp ? "Sign up" : "Sign in",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isSignUp
                            ? "Already have an account? Sign in"
                            : "New here? Create an account",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
