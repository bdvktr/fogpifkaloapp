int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  final s = (value ?? '').toString();
  return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class AdminOrder {
  final int id;
  final DateTime createdAt;
  final String status;
  final double totalPrice;
  final String userEmail;

  AdminOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalPrice,
    required this.userEmail,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: _toInt(json['id']),
      createdAt: _toDateTime(json['created_at']),
      status: (json['status'] ?? '') as String,
      totalPrice: _toDouble(json['total_price']),
      userEmail: (json['user_email'] ?? '') as String,
    );
  }
}
