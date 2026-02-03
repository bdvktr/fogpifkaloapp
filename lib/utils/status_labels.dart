const Map<String, String> _statusHu = {
  'pending': 'Függőben',
  'in_progress': 'Folyamatban',
  'processing': 'Folyamatban',

  'approved': 'Elfogadva',
  'accepted': 'Elfogadva',

  'rejected': 'Elutasítva', 
  'declined': 'Elutasítva',

  'cancelled': 'Törölve',
  'canceled': 'Törölve',

  'delivered': 'Kiszállítva',
  'completed': 'Teljesítve',
  'cash' : 'Készpénz',
  'card' : 'Kártya',
};

String huStatusLabelOf(String raw) {
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return 'Ismeretlen';
  return _statusHu[key] ?? raw; // ha nincs mapping, marad az eredeti
}

extension HuStatusLabelX on String {
  String get huStatusLabel => huStatusLabelOf(this);
}
