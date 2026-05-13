import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:e_commerce_flutter/src/model/purchase_history_item.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  PurchaseHistoryScreen({super.key});

  final List<PurchaseHistoryItem> purchases = [
    PurchaseHistoryItem(
      title: "Apple Watch 7",
      date: DateTime(2026, 5, 10),
      total: "\$360",
      status: "Delivered",
    ),
    PurchaseHistoryItem(
      title: "Samsung Galaxy A53 5G",
      date: DateTime(2026, 4, 28),
      total: "\$300",
      status: "Delivered",
    ),
    PurchaseHistoryItem(
      title: "Beats studio 3",
      date: DateTime(2026, 3, 16),
      total: "\$230",
      status: "Delivered",
    ),
    PurchaseHistoryItem(
      title: "Samsung Q60 A",
      date: DateTime(2026, 2, 4),
      total: "\$560",
      status: "Delivered",
    ),
    PurchaseHistoryItem(
      title: "Samsung Galaxy Watch 4",
      date: DateTime(2026, 1, 19),
      total: "\$215",
      status: "Delivered",
    ),
  ]..sort((a, b) => b.date.compareTo(a.date));

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

  Widget _purchaseTile(PurchaseHistoryItem purchase) {
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
                  purchase.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_formatDate(purchase.date)} - ${purchase.status}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            purchase.total,
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
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: purchases.map(_purchaseTile).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
