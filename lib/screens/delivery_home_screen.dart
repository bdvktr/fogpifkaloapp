import 'package:flutter/material.dart';

import '../models/user.dart';
import '../repositories/delivery_repository.dart';
import 'completed_orders_screen.dart';
import 'orders_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  final DeliveryRepository deliveryRepository;
  final User currentUser;
  final String socketUrl;

  const DeliveryHomeScreen({
    super.key,
    required this.deliveryRepository,
    required this.currentUser,
    required this.socketUrl,
  });

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          OrdersScreen(
            deliveryRepository: widget.deliveryRepository,
            currentUser: widget.currentUser,
            socketUrl: widget.socketUrl,
          ),
          CompletedOrdersScreen(
            deliveryRepository: widget.deliveryRepository,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Rendelések',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Előzmények',
          ),
        ],
      ),
    );
  }
}
