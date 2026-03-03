int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  final s = (value ?? '').toString();
  return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String _toStringSafe(dynamic v) => (v ?? '').toString();

String _timeHHMM(dynamic v) {
  final s = _toStringSafe(v);
  if (s.isEmpty) return '';
  // jöhet "18:30:00" -> "18:30"
  if (s.length >= 5) return s.substring(0, 5);
  return s;
}

class AdminReservation {
  final int id;
  final int tableNumber;
  final DateTime reservationDate; // dátum (nap)
  final String timeFrom; // HH:MM
  final String timeTo; // HH:MM
  final String name;
  final String email;
  final String phone;
  final int peopleCount;
  final String note;
  final String status;
  final DateTime createdAt;

  AdminReservation({
    required this.id,
    required this.tableNumber,
    required this.reservationDate,
    required this.timeFrom,
    required this.timeTo,
    required this.name,
    required this.email,
    required this.phone,
    required this.peopleCount,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  factory AdminReservation.fromJson(Map<String, dynamic> json) {
    return AdminReservation(
      id: _toInt(json['id']),
      tableNumber: _toInt(json['table_number']),
      reservationDate: _toDateTime(json['reservation_date']),
      timeFrom: _timeHHMM(json['reservation_time']),
      timeTo: _timeHHMM(json['end_time']),
      name: _toStringSafe(json['name']),
      email: _toStringSafe(json['email']),
      phone: _toStringSafe(json['phone']),
      peopleCount: _toInt(json['people_count']),
      note: _toStringSafe(json['note']),
      status: _toStringSafe(json['status']),
      createdAt: _toDateTime(json['created_at']),
    );
  }
}
