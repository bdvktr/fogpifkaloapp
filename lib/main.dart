import 'package:flutter/material.dart';

import 'api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/delivery_repository.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const baseUrl = 'http://192.168.11.13:3000/api';

    final apiClient = ApiClient(baseUrl: baseUrl);
    final authRepo = AuthRepository(apiClient: apiClient);
    final deliveryRepo = DeliveryRepository(apiClient: apiClient);

    return MaterialApp(
      title: 'Burger Futár',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: WelcomeScreen(
        authRepository: authRepo,
        deliveryRepository: deliveryRepo,
        apiClient: apiClient,
      ),
    );
  }
}
