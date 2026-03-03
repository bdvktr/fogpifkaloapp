import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../repositories/delivery_repository.dart';
import '../models/delivery_order.dart';
import '../models/user.dart';
import '../utils/status_labels.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final DeliveryRepository deliveryRepository;
  final User currentUser;
  final String socketUrl;

  const OrdersScreen({
    super.key,
    required this.deliveryRepository,
    required this.currentUser,
    required this.socketUrl,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<DeliveryOrder>> _futureOrders;
  IO.Socket? _socket;

  // Theme-szerű színek
  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _surface = Colors.white;
  static const Color _priceOrange = Color(0xFFF2994A);
  static const Color _text = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);

  static const Color _blueA = Color(0xFF67D5FF);
  static const Color _blueB = Color(0xFF2D9CDB);

  static const Color _greenA = Color(0xFF34D399);
  static const Color _greenB = Color(0xFF22C55E);

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
    _futureOrders = widget.deliveryRepository.fetchPendingOrders();
    _setupSocket();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureOrders = widget.deliveryRepository.fetchPendingOrders();
    });
    await _futureOrders;
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  bool _isWaiting(String status) {
    final s = status.trim().toLowerCase();
    return s == 'pending' || s == 'waiting';
  }

  bool _isDelivering(String status) {
    final s = status.trim().toLowerCase();
    return s == 'in_progress' ||
        s == 'delivering' ||
        s == 'processing' ||
        s == 'accepted' ||
        s == 'approved';
  }

  Color _statusColor(String status) {
    final s = status.trim().toLowerCase();
    if (_isWaiting(s)) return const Color(0xFFEB5757);
    if (_isDelivering(s)) return const Color(0xFFF2C94C);
    if (s == 'delivered' || s == 'completed') return const Color(0xFF27AE60);
    return const Color(0xFF9CA3AF);
  }

  String _statusChipText(DeliveryOrder o) {
    // Ha szeretnéd fixre: WAITING / DELIVERING — szólj és átírom
    return o.status.huStatusLabel.toUpperCase();
  }

  Widget _statusChip(String status, String text) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _pillGradientButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 38,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: colors,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 26),
                child: Center(
                  child: Text(
                    '',
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
    );
  }

  // AppBar (theme-hez illő)
  PreferredSizeWidget _buildTopBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                // bal oldali hely (ha később kell logout/back)
                const SizedBox(width: 40),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Rendelések - Futár',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  color: Colors.black.withOpacity(0.55),
                  tooltip: 'Frissítés',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndComplete(DeliveryOrder o) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rendelés átadva?'),
        content: Text('Biztosan átadva jelölöd a #${o.id} rendelést?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Igen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.deliveryRepository.completeOrder(o.id);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rendelés #${o.id} teljesítve.')));

      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  void _openDetail(DeliveryOrder o) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: o.id,
          deliveryRepository: widget.deliveryRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildTopBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<DeliveryOrder>>(
          future: _futureOrders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Hiba történt:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                children: const [
                  SizedBox(height: 90),
                  Center(
                    child: Text(
                      'Jelenleg nincs rendelés.',
                      style: TextStyle(fontSize: 16, color: _muted),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final o = orders[index];

                final buttonText = 'RENDELÉS RÉSZLETEI';

                final buttonColors = const [_blueA, _blueB];

                return GestureDetector(
                  onTap: () => _openDetail(o),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
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
                        // TOP: Order + price + status
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
                            _statusChip(o.status, _statusChipText(o)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // DATE
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.black.withOpacity(0.45),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(o.createdAt),
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.55),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // CUSTOMER
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
                                '${o.userName} (${o.userEmail})',
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

                        // CTA (középen)
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            height: 38,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Material(
                                color: Colors.transparent,
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: buttonColors,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _openDetail(o);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 26,
                                      ),
                                      child: Center(
                                        child: Text(
                                          buttonText,
                                          style: const TextStyle(
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
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
