import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/admin_order.dart';
import '../repositories/admin_repository.dart';
import '../utils/status_labels.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  final AdminRepository adminRepository;
  final String socketUrl;

  const AdminOrdersScreen({
    super.key,
    required this.adminRepository,
    required this.socketUrl,
  });

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late Future<List<AdminOrder>> _future;
  IO.Socket? _socket;

  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _surface = Colors.white;
  static const Color _priceOrange = Color(0xFFF2994A);
  static const Color _text = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);

  void _setupSocket() {
    final socket = IO.io(
      widget.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.on('pendingOrdersUpdated', (_) {
      _refresh();
    });

    socket.connect();
    _socket = socket;
  }

  @override
  void initState() {
    super.initState();
    _future = widget.adminRepository.fetchOrders();
    _setupSocket();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.adminRepository.fetchOrders();
    });
    await _future;
  }

  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Color _statusColor(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'pending':
        return const Color(0xFFF2C94C);
      case 'completed':
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

  Future<void> _changeStatus(AdminOrder o, String newStatus) async {
    if (newStatus == o.status) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Státusz módosítás'),
        content: Text(
          'Rendelés #${o.id}\n'
          'Új státusz: ${newStatus.huStatusLabel}\n\n'
          'Biztosan módosítod?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Módosítom'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.adminRepository.updateOrderStatus(o.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Státusz frissítve.')));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  void _openDetail(AdminOrder o) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminOrderDetailScreen(
          orderId: o.id,
          adminRepository: widget.adminRepository,
        ),
      ),
    );
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

  Widget _orderCard(AdminOrder o) {
    return GestureDetector(
      onTap: () => _openDetail(o),
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rendelés #${o.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o.totalPrice.toStringAsFixed(0)} Ft',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _priceOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _changeStatus(o, v),
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'pending', child: Text('Folyamatban')),
                    PopupMenuItem(
                      value: 'completed',
                      child: Text('Teljesítve'),
                    ),
                    PopupMenuItem(value: 'cancelled', child: Text('Törölve')),
                  ],
                  child: _statusChip(o.status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.black.withOpacity(0.45),
                ),
                const SizedBox(width: 6),
                Text(
                  _fmtDate(o.createdAt),
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.black.withOpacity(0.45),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    o.userEmail,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: 38,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF67D5FF), Color(0xFF2D9CDB)],
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _openDetail(o),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 26),
                          child: Center(
                            child: Text(
                              'RÉSZLETEK MEGTEKINTÉSE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminOrder>>(
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
                  Center(child: Text('Még nincsenek rendelések.')),
                ],
              );
            }

            final pending = all.where((o) => o.status == 'pending').toList();
            final completed = all
                .where((o) => o.status == 'completed')
                .toList();
            final cancelled = all
                .where((o) => o.status == 'cancelled' || o.status == 'canceled')
                .toList();

            return ListView(
              children: [
                _sectionTitle('Folyamatban'),
                if (pending.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      'Nincs folyamatban lévő rendelés.',
                      style: TextStyle(color: _muted),
                    ),
                  )
                else
                  ...pending.map(_orderCard),

                _sectionTitle('Teljesítve'),
                if (completed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      'Nincs teljesített rendelés.',
                      style: TextStyle(color: _muted),
                    ),
                  )
                else
                  ...completed.map(_orderCard),

                _sectionTitle('Törölve'),
                if (cancelled.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Text(
                      'Nincs törölt rendelés.',
                      style: TextStyle(color: _muted),
                    ),
                  )
                else
                  ...cancelled.map(_orderCard),

                const SizedBox(height: 18),
              ],
            );
          },
        ),
      ),
    );
  }
}
