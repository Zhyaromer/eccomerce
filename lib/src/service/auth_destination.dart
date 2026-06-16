import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/src/view/screen/admin_dashboard_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/email_verification_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/home_screen.dart';

class AuthDestination {
  const AuthDestination._();

  static Future<bool> isAdmin(User user) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = snapshot.data()?['role']?.toString().trim().toLowerCase();

      return role == 'admin';
    } on FirebaseException {
      return false;
    }
  }

  static Future<Widget> forSignedInUser(User user) async {
    if (!user.emailVerified) {
      return const EmailVerificationScreen();
    }

    if (await isAdmin(user)) {
      return const AdminDashboardScreen();
    }

    return const HomeScreen();
  }
}
