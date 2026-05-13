import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_flutter/core/app_color.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 54,
              color: AppColor.darkOrange,
            ),
            SizedBox(height: 14),
            Text(
              "No purchases yet",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              "Checkout your cart and your orders will show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purchaseTile(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final createdAt = data['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    final total = _readInt(data['total']);
    final status = data['status'] as String? ?? 'Purchased';
    final title = items.isEmpty
        ? 'Purchase'
        : items.length == 1
            ? items.first['productName'] as String? ?? 'Purchase'
            : '${items.length} items purchased';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: Color(0xFF23814D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_formatDate(date)} - $status",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final name = item['productName'] as String? ?? 'Item';
                    final quantity = _readInt(item['quantity'], fallback: 1);
                    final size = item['sizeLabel'] as String? ?? 'Default';

                    return Text(
                      "$quantity x $name ($size)",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          Text(
            "\$$total",
            style: const TextStyle(
              color: AppColor.darkOrange,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text(
          "Purchase history",
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: user == null
                ? _emptyState()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('purchases')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColor.darkOrange,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              "Could not load purchase history.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      final purchases = snapshot.data?.docs ?? [];
                      if (purchases.isEmpty) {
                        return _emptyState();
                      }

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: purchases.map(_purchaseTile).toList(),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
