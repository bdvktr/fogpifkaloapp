import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../repositories/delivery_repository.dart';
import '../models/delivery_order_detail.dart';
import '../utils/status_labels.dart';

class _TravelInfo {
  final double distanceKm;
  final int durationMin;

  const _TravelInfo({required this.distanceKm, required this.durationMin});
}

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final DeliveryRepository deliveryRepository;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.deliveryRepository,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<DeliveryOrderDetail> _futureDetail;

  // Étterem (Átvétel) – innen számoljuk a távolságot autóval
  static const String pickupTitle = 'Átvétel';
  static const String pickupPlace = 'FogPifkáló';
  static const String pickupAddress = 'Mohács, Szabadság u. 18, 7700';

  // Light UI színek
  static const Color _bg = Color(0xFFF6F7F9);
  static const Color _surface = Colors.white;
  static const Color _primaryBlue = Color(0xFF2D9CDB);
  static const Color _priceOrange = Color(0xFFF2994A);
  static const Color _text = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);

  Future<_TravelInfo?>? _futureTravel;
  _TravelInfo? _travelCache;

  final Dio _geoDio = Dio(
    BaseOptions(
      headers: {
        // Nominatim elvárja
        'User-Agent': 'FogPifkaloCourier/1.0',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  @override
  void initState() {
    super.initState();

    _futureDetail = widget.deliveryRepository.fetchOrderDetail(widget.orderId);

    _futureTravel = _futureDetail.then((detail) {
      return _fetchTravelInfo(
        fromAddress: pickupAddress,
        toAddress: detail.shippingAddress,
      );
    });
  }

  // --- Gradient gomb (kisebb) ---
  Widget _gradientActionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF67D5FF), // világos kék
                      Color(0xFF2D9CDB), // primary kék
                    ],
                  )
                : null,
            color: enabled ? null : const Color(0xFFBDBDBD),
          ),
          child: InkWell(
            onTap: onPressed,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Átadva',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- travel helpers ---
  String _formatKm(double km) {
    if (km < 10) return km.toStringAsFixed(1);
    return km.toStringAsFixed(0);
  }

  Future<Map<String, double>?> _geocodeAddress(String address) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=json&limit=1&q=${Uri.encodeComponent(address)}',
    );

    final resp = await _geoDio.getUri(uri);
    if (resp.statusCode != 200 || resp.data == null) return null;

    final list = resp.data as List<dynamic>;
    if (list.isEmpty) return null;

    final item = list.first as Map<String, dynamic>;
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    return {'lat': lat, 'lon': lon};
  }

  Future<_TravelInfo?> _fetchTravelInfo({
    required String fromAddress,
    required String toAddress,
  }) async {
    if (_travelCache != null) return _travelCache;

    final from = await _geocodeAddress(fromAddress);
    final to = await _geocodeAddress(toAddress);
    if (from == null || to == null) return null;

    final lon1 = from['lon']!;
    final lat1 = from['lat']!;
    final lon2 = to['lon']!;
    final lat2 = to['lat']!;

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$lon1,$lat1;$lon2,$lat2?overview=false',
    );

    final resp = await _geoDio.getUri(uri);
    if (resp.statusCode != 200 || resp.data == null) return null;

    final data = resp.data as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    final r0 = routes.first as Map<String, dynamic>;
    final meters = (r0['distance'] as num).toDouble();
    final seconds = (r0['duration'] as num).toDouble();

    final info = _TravelInfo(
      distanceKm: meters / 1000.0,
      durationMin: (seconds / 60).round(),
    );

    _travelCache = info;
    return info;
  }

  // --- ui helpers ---
  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  int _itemsCount(List<OrderItem> items) {
    return items.fold<int>(0, (sum, it) => sum + it.quantity);
  }

  Color _statusColor(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'pending':
        return const Color(0xFFEB5757);
      case 'in_progress':
      case 'processing':
      case 'accepted':
      case 'approved':
        return const Color(0xFFF2C94C);
      case 'delivered':
      case 'completed':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Future<void> _markCompleted(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rendelés átadva?'),
        content: Text('Biztosan átadva jelölöd a #$orderId rendelést?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Igen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.deliveryRepository.completeOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rendelés #$orderId teljesítve.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _muted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _kvRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapPlaceholder() {
    return Container(
      height: 270,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF3),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'Térkép (hamarosan)',
              style: TextStyle(color: Colors.black.withOpacity(0.45)),
            ),
          ),
          Positioned(
            top: 52,
            left: 16,
            child: Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.12),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FutureBuilder<DeliveryOrderDetail>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Hiba a rendelés betöltésekor:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final detail = snapshot.data!;
          final items = detail.items;
          final itemCount = _itemsCount(items);
          final statusColor = _statusColor(detail.status);

          return Column(
            children: [
              _mapPlaceholder(),
              Expanded(
                child: Container(
                  color: _surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                    child: FutureBuilder<_TravelInfo?>(
                      future: _futureTravel,
                      builder: (context, travelSnap) {
                        final travel = travelSnap.data;

                        final kmText = (travel == null)
                            ? '—'
                            : _formatKm(travel.distanceKm);
                        final minText = (travel == null)
                            ? '—'
                            : '${travel.durationMin} perc';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER + karika
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rendelés #${detail.id}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: _text,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$itemCount tétel • $minText autóval • ${_formatDate(detail.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: _muted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _priceOrange,
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          kmText,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: _text,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Text(
                                          'km',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Státusz chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                detail.status.huStatusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Route blokk
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.06),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // PICKUP sor (intrinsic height, hogy a bal oldali Stack kapjon rendes magasságot)
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          child: Stack(
                                            children: [
                                              // narancs pont (4px lejjebb, hogy a szöveg tetejéhez passzoljon)
                                              Positioned(
                                                top: 4,
                                                left: 4, // (18-10)/2
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFFF2994A,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ),
                                              // vonal a pont aljától (2px hézaggal) a sor aljáig
                                              Positioned(
                                                top:
                                                    16, // 4(top) + 10(dot) + 2(gap)
                                                bottom: 0,
                                                left: 8, // (18-2)/2
                                                child: Container(
                                                  width: 2,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.10),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          99,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
                                                Text(
                                                  pickupTitle,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _muted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  pickupPlace,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: _text,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  pickupAddress,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: _muted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            '0 km',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // KÖZTES VONAL rész (fix magasság, a két sor között)
                                  SizedBox(
                                    height: 10,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          child: Center(
                                            child: Container(
                                              width: 2,
                                              height: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.10,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ),

                                  // DELIVER sor (intrinsic height)
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          child: Stack(
                                            children: [
                                              // vonal felülről a kék pont tetejéig (2px hézag)
                                              Positioned(
                                                top: 0,
                                                left: 8,
                                                child: Container(
                                                  width: 2,
                                                  height:
                                                      2, // 4(top) - 2(gap) = 2 -> egyenlő távolság
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.10),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          99,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              // kék pont
                                              Positioned(
                                                top: 4,
                                                left: 4,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFF2D9CDB,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Kiszállítás',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _muted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  detail.shippingAddress,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: _text,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            '$kmText km',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: _text,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // CTA + ár  (MÓDOSÍTVA: kisebb + gradient)
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38, // kisebb
                                    child: _gradientActionButton(
                                      label:
                                          (detail.status.toLowerCase() ==
                                              'completed')
                                          ? 'Teljesítve'
                                          : 'Átadva',
                                      onPressed:
                                          (detail.status.toLowerCase() ==
                                              'completed')
                                          ? null
                                          : () => _markCompleted(detail.id),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  '${detail.totalPrice.toStringAsFixed(0)} Ft',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: _priceOrange,
                                  ),
                                ),
                              ],
                            ),

                            // Sections
                            _sectionCard(
                              title: 'Ügyfél',
                              children: [
                                _kvRow(
                                  Icons.person,
                                  'Név',
                                  detail.shippingName,
                                ),
                                const SizedBox(height: 10),
                                _kvRow(
                                  Icons.phone,
                                  'Telefon',
                                  detail.shippingPhone,
                                ),
                                const SizedBox(height: 10),
                                _kvRow(Icons.email, 'Email', detail.userEmail),
                              ],
                            ),

                            _sectionCard(
                              title: 'Szállítás',
                              children: [
                                _kvRow(
                                  Icons.location_on,
                                  'Cím',
                                  detail.shippingAddress,
                                ),
                                const SizedBox(height: 10),
                                _kvRow(
                                  Icons.payments,
                                  'Fizetés',
                                  detail.paymentMethod.isEmpty
                                      ? '—'
                                      : detail.paymentMethod.huStatusLabel,
                                ),
                                if (detail.note.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _kvRow(
                                    Icons.note_alt_outlined,
                                    'Megjegyzés',
                                    detail.note,
                                  ),
                                ],
                              ],
                            ),

                            _sectionCard(
                              title: 'Tételek',
                              children: [
                                if (items.isEmpty)
                                  const Text(
                                    'Nincsenek tételek.',
                                    style: TextStyle(color: _muted),
                                  ),
                                if (items.isNotEmpty)
                                  ...items
                                      .expand(
                                        (it) => [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      it.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: _text,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'Mennyiség: ${it.quantity} × ${it.unitPrice.toStringAsFixed(0)} Ft',
                                                      style: const TextStyle(
                                                        color: _muted,
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                          Divider(
                                            height: 18,
                                            color: Colors.black.withOpacity(
                                              0.06,
                                            ),
                                          ),
                                        ],
                                      )
                                      .toList()
                                    ..removeLast(),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
