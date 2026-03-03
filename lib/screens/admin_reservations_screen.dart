import 'package:flutter/material.dart';

import '../models/admin_reservation.dart';
import '../repositories/admin_repository.dart';
import '../utils/status_labels.dart';

class AdminReservationsScreen extends StatefulWidget {
  final AdminRepository adminRepository;

  const AdminReservationsScreen({
    super.key,
    required this.adminRepository,
  });

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  late Future<List<AdminReservation>> _future;

  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _future = widget.adminRepository.fetchReservations();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.adminRepository.fetchReservations();
    });
    await _future;
  }

  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)}';
  }

  Color _statusColor(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'pending':
        return const Color(0xFFF2C94C);
      case 'confirmed':
        return const Color(0xFF27AE60);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFEB5757);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Widget _statusChip(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c),
      ),
      child: Text(
        status.huStatusLabel.toUpperCase(),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Future<void> _changeStatus(AdminReservation r, String newStatus) async {
    if (newStatus == r.status) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Státusz módosítás'),
        content: Text(
          'Foglalás #${r.id}\n'
          'Új státusz: ${newStatus.huStatusLabel}\n\n'
          'Biztosan módosítod?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Mégse')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Módosítom')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.adminRepository.updateReservationStatus(r.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Státusz frissítve.')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba: $e')),
      );
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: _text,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _card(AdminReservation r) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FOGLALÁS #${r.id} • Asztal ${r.tableNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _changeStatus(r, v),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'pending', child: Text('Függőben')),
                  PopupMenuItem(value: 'confirmed', child: Text('Visszaigazolva')),
                  PopupMenuItem(value: 'cancelled', child: Text('Törölve')),
                ],
                child: _statusChip(r.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_fmtDate(r.reservationDate)} • ${r.timeFrom}–${r.timeTo} • ${r.peopleCount} fő',
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${r.name} • ${r.phone}',
            style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            r.email,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
          ),
          if (r.note.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Megjegyzés: ${r.note}',
              style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminReservation>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Hiba:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            }

            final all = snap.data ?? [];
            if (all.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Még nincsenek foglalások.')),
                ],
              );
            }

            final pending = all.where((r) => r.status == 'pending').toList();
            final confirmed = all.where((r) => r.status == 'confirmed').toList();
            final cancelled = all.where((r) => r.status == 'cancelled' || r.status == 'canceled').toList();

            return ListView(
              children: [
                _sectionTitle('Függőben'),
                if (pending.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text('Nincs függő foglalás.', style: TextStyle(color: _muted)),
                  )
                else
                  ...pending.map(_card),

                _sectionTitle('Visszaigazolva'),
                if (confirmed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text('Nincs visszaigazolt foglalás.', style: TextStyle(color: _muted)),
                  )
                else
                  ...confirmed.map(_card),

                _sectionTitle('Törölve'),
                if (cancelled.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text('Nincs törölt foglalás.', style: TextStyle(color: _muted)),
                  )
                else
                  ...cancelled.map(_card),

                const SizedBox(height: 18),
              ],
            );
          },
        ),
      ),
    );
  }
}
