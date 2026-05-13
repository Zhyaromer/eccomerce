class PurchaseHistoryItem {
  final String title;
  final DateTime date;
  final String total;
  final String status;

  const PurchaseHistoryItem({
    required this.title,
    required this.date,
    required this.total,
    required this.status,
  });
}
