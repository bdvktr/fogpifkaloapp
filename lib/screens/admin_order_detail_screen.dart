import 'package:flutter/material.dart';

import '../models/admin_order_detail.dart';
import '../repositories/admin_repository.dart';
import '../utils/status_labels.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;
  final AdminRepository adminRepository;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.adminRepository,
  });

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late Future<AdminOrderDetail> _future;

  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _priceOrange = Color(0xFFF2994A);

  @override
  void initState() {
    super.initState();
    _future = widget.adminRepository.fetchOrderDetail(widget.orderId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.adminRepository.fetchOrderDetail(widget.orderId);
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

  Future<void> _setStatus(AdminOrderDetail detail, String newStatus) async {
    if (newStatus == detail.status) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Státusz módosítás'),
        content: Text(
          'Rendelés #${detail.id}\n'
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
      await widget.adminRepository.updateOrderStatus(detail.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Státusz frissítve.')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _muted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Rendelés #${widget.orderId}'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<AdminOrderDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Hiba:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            children: [
              Container(
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
                            'Rendelés #${d.id}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ),
                        _statusChip(d.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Dátum: ${_fmtDate(d.createdAt)}',
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vevő: ${d.user.name} (${d.user.email})',
                      style: const TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 18, color: _muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.shippingAddress.isEmpty ? '—' : d.shippingAddress,
                            style: const TextStyle(
                              color: _text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Végösszeg:',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${d.totalPrice.toStringAsFixed(0)} Ft',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _priceOrange,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (v) => _setStatus(d, v),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                              value: 'pending',
                              child: Text('Folyamatban'),
                            ),
                            PopupMenuItem(
                              value: 'completed',
                              child: Text('Teljesítve'),
                            ),
                            PopupMenuItem(
                              value: 'cancelled',
                              child: Text('Törölve'),
                            ),
                          ],
                          child: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _sectionCard(
                title: 'Tételek',
                child: Column(
                  children: d.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _text,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Mennyiség: ${it.quantity} × ${it.unitPrice.toStringAsFixed(0)} Ft',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${it.lineTotal.toStringAsFixed(0)} Ft',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
