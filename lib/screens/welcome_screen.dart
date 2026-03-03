import 'package:flutter/material.dart';

import '../api_client.dart';
import '../repositories/admin_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/delivery_repository.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final DeliveryRepository deliveryRepository;
  final AdminRepository adminRepository;
  final ApiClient apiClient;
  final String socketUrl;

  const WelcomeScreen({
    super.key,
    required this.authRepository,
    required this.deliveryRepository,
    required this.adminRepository,
    required this.apiClient,
    required this.socketUrl,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade600;
    final secondaryColor = Colors.blue.shade900;

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                flex: 5,
                child: Center(
                  child: SizedBox(
                    height: screenHeight * 0.45,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          minimumSize: const Size(260, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(
                                authRepository: widget.authRepository,
                                deliveryRepository: widget.deliveryRepository,
                                adminRepository: widget.adminRepository,
                                apiClient: widget.apiClient,
                                socketUrl: widget.socketUrl,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Tovább a bejelentkezéshez',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
