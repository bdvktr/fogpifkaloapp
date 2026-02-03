import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/delivery_repository.dart';
import 'screens/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Konfig: futtatható --dart-define-dal is
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  const socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  final appSupportDir = await getApplicationSupportDirectory();
  final cookieDirPath = '${appSupportDir.path}/cookies';
  await Directory(cookieDirPath).create(recursive: true);

  final navigatorKey = GlobalKey<NavigatorState>();

  late final ApiClient apiClient;
  late final AuthRepository authRepo;
  late final DeliveryRepository deliveryRepo;

  apiClient = ApiClient(
    baseUrl: apiBaseUrl,
    cookieStoragePath: cookieDirPath,
    onSessionExpired: () {
      final nav = navigatorKey.currentState;
      if (nav == null) return;

      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => StartupScreen(
            authRepository: authRepo,
            deliveryRepository: deliveryRepo,
            apiClient: apiClient,
            socketUrl: socketUrl,
          ),
        ),
        (_) => false,
      );
    },
  );

  authRepo = AuthRepository(apiClient: apiClient);
  deliveryRepo = DeliveryRepository(apiClient: apiClient);

  runApp(
    DeliveryApp(
      navigatorKey: navigatorKey,
      apiClient: apiClient,
      authRepository: authRepo,
      deliveryRepository: deliveryRepo,
      socketUrl: socketUrl,
    ),
  );
}

class DeliveryApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final DeliveryRepository deliveryRepository;
  final String socketUrl;

  const DeliveryApp({
    super.key,
    required this.navigatorKey,
    required this.apiClient,
    required this.authRepository,
    required this.deliveryRepository,
    required this.socketUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Burger Futár',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        useMaterial3: true,
      ),
      home: StartupScreen(
        authRepository: authRepository,
        deliveryRepository: deliveryRepository,
        apiClient: apiClient,
        socketUrl: socketUrl,
      ),
    );
  }
}
