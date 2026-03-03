import 'package:flutter/material.dart';

import '../repositories/admin_repository.dart';
import 'admin_orders_screen.dart';
import 'admin_reservations_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final AdminRepository adminRepository;
  final String socketUrl;

  const AdminHomeScreen({
    super.key,
    required this.adminRepository,
    required this.socketUrl,
  });

  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(112),
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
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      labelColor: _text,
                      unselectedLabelColor: _text.withOpacity(0.55),
                      indicatorColor: _text,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                      tabs: const [
                        Tab(text: 'Rendelések'),
                        Tab(text: 'Foglalások'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            AdminOrdersScreen(
              adminRepository: adminRepository,
              socketUrl: socketUrl,
            ),
            AdminReservationsScreen(
              adminRepository: adminRepository,
            ),
          ],
        ),
      ),
    );
  }
}
