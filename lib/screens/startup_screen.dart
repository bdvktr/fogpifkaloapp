import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/delivery_repository.dart';
import 'welcome_screen.dart';
import 'delivery_home_screen.dart';

class StartupScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final DeliveryRepository deliveryRepository;
  final ApiClient apiClient;
  final String socketUrl;

  const StartupScreen({
    super.key,
    required this.authRepository,
    required this.deliveryRepository,
    required this.apiClient,
    required this.socketUrl,
  });

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  late final Future<User?> _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = widget.authRepository.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _futureUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return DeliveryHomeScreen(
            deliveryRepository: widget.deliveryRepository,
            currentUser: user,
            socketUrl: widget.socketUrl,
          );
        }

        return WelcomeScreen(
          authRepository: widget.authRepository,
          deliveryRepository: widget.deliveryRepository,
          apiClient: widget.apiClient,
          socketUrl: widget.socketUrl,
        );
      },
    );
  }
}
