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

String _toStringSafe(dynamic v) => (v ?? '').toString();

class AdminOrderItem {
  final int productId;
  final String name;
  final int quantity;
  final double unitPrice;

  AdminOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      productId: _toInt(json['product_id']),
      name: _toStringSafe(json['name']),
      quantity: _toInt(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
    );
  }
}

class AdminOrderDetailUser {
  final String name;
  final String email;

  AdminOrderDetailUser({required this.name, required this.email});

  factory AdminOrderDetailUser.fromJson(Map<String, dynamic> json) {
    return AdminOrderDetailUser(
      name: _toStringSafe(json['name']),
      email: _toStringSafe(json['email']),
    );
  }
}

class AdminOrderDetail {
  final int id;
  final DateTime createdAt;
  final String status;
  final double totalPrice;

  // ✅ ÚJ: szállítási adatok
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final String note;
  final String paymentMethod;

  final AdminOrderDetailUser user;
  final List<AdminOrderItem> items;

  AdminOrderDetail({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalPrice,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddress,
    required this.note,
    required this.paymentMethod,
    required this.user,
    required this.items,
  });

  factory AdminOrderDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = (json['items'] ?? []) as List<dynamic>;

    return AdminOrderDetail(
      id: _toInt(json['id']),
      createdAt: _toDateTime(json['created_at']),
      status: _toStringSafe(json['status']),
      totalPrice: _toDouble(json['total_price']),

      // ✅ ezek a te backendedben benne vannak a delivery detailnél,
      // és admin detailnél is ugyanígy érdemes visszaadni
      shippingName: _toStringSafe(json['shipping_name']),
      shippingPhone: _toStringSafe(json['shipping_phone']),
      shippingAddress: _toStringSafe(json['shipping_address']),
      note: _toStringSafe(json['note']),
      paymentMethod: _toStringSafe(json['payment_method']),

      user: AdminOrderDetailUser.fromJson(json['user'] as Map<String, dynamic>),
      items: itemsJson
          .map((e) => AdminOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
