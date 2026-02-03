import 'package:flutter/material.dart';

import '../models/delivery_order.dart';
import '../repositories/delivery_repository.dart';

class CompletedOrdersScreen extends StatefulWidget {
  final DeliveryRepository deliveryRepository;

  const CompletedOrdersScreen({
    super.key,
    required this.deliveryRepository,
  });

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  bool _loading = true;
  String? _error;
  List<DeliveryOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await widget.deliveryRepository.fetchCompletedOrders();
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _undo(DeliveryOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Visszavonás'),
        content: Text(
          'Biztosan visszavonod a rendelés átadását?\n'
          'Rendelés #${order.id}\n'
          '${order.shippingName} — ${order.shippingAddress}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Visszavonom'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.deliveryRepository.undoCompleteOrder(order.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendelés visszavonva (pending).')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Előzmények (leadott rendelések)'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Újra'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _orders.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Még nincs leadott rendelés.')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final o = _orders[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rendelés #${o.id} • ${_fmtDate(o.createdAt)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Név: ${o.shippingName}'),
                                    Text('Telefon: ${o.shippingPhone}'),
                                    Text('Cím: ${o.shippingAddress}'),
                                    const SizedBox(height: 6),
                                    Text('Összeg: ${o.totalPrice.toStringAsFixed(0)} Ft'),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        FilledButton.icon(
                                          onPressed: () => _undo(o),
                                          icon: const Icon(Icons.undo),
                                          label: const Text('Visszavonás'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
