import 'package:flutter/material.dart';

import '../models/user.dart';
import '../repositories/admin_repository.dart';
import '../repositories/delivery_repository.dart';
import 'admin_home_screen.dart';
import 'completed_orders_screen.dart';
import 'orders_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  final DeliveryRepository deliveryRepository;
  final AdminRepository adminRepository;
  final User currentUser;
  final String socketUrl;

  const DeliveryHomeScreen({
    super.key,
    required this.deliveryRepository,
    required this.adminRepository,
    required this.currentUser,
    required this.socketUrl,
  });

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _HomeTab {
  final Widget page;
  final BottomNavigationBarItem item;

  _HomeTab({required this.page, required this.item});
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _index = 0;
  late final List<_HomeTab> _tabs;

  @override
  void initState() {
    super.initState();

    final tabs = <_HomeTab>[];

    if (widget.currentUser.isDelivery) {
      tabs.add(
        _HomeTab(
          page: OrdersScreen(
            deliveryRepository: widget.deliveryRepository,
            currentUser: widget.currentUser,
            socketUrl: widget.socketUrl,
          ),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Rendelések',
          ),
        ),
      );

      tabs.add(
        _HomeTab(
          page: CompletedOrdersScreen(
            deliveryRepository: widget.deliveryRepository,
          ),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Előzmények',
          ),
        ),
      );
    }

    if (widget.currentUser.isAdmin) {
      tabs.add(
        _HomeTab(
          page: AdminHomeScreen(
            adminRepository: widget.adminRepository,
            socketUrl: widget.socketUrl,
          ),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ),
      );
    }

    _tabs = tabs;
  }

  @override
  Widget build(BuildContext context) {
    // Ha csak 1 tab van (pl admin-only), akkor ne legyen alul nav
    if (_tabs.length == 1) {
      return _tabs.first.page;
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs.map((t) => t.page).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: _tabs.map((t) => t.item).toList(),
      ),
    );
  }
}
