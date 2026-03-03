import 'package:dio/dio.dart';

import '../api_client.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<User> login({required String email, required String password}) async {
    final dio = apiClient.dio;

    final response = await dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    if (response.statusCode != 200) {
      final message = response.data is Map<String, dynamic>
          ? (response.data['message'] ?? 'Ismeretlen hiba')
          : 'Hibás email vagy jelszó.';
      throw Exception(message);
    }

    final meResponse = await dio.get(
      '/me',
      options: Options(extra: {'__suppressSessionExpired': true}),
    );

    if (meResponse.statusCode != 200 ||
        meResponse.data == null ||
        meResponse.data['loggedIn'] != true) {
      throw Exception('Nem sikerült lekérdezni a felhasználói adatokat.');
    }

    final userJson = meResponse.data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userJson);

    // ✅ Most már admin is beléphet (vagy futár, vagy admin, vagy mindkettő)
    if (!user.isDelivery && !user.isAdmin) {
      throw Exception(
        'Ez a fiók nem jogosult az alkalmazás használatára.',
      );
    }

    return user;
  }

  Future<User?> getCurrentUser() async {
    final dio = apiClient.dio;
    final response = await dio.get(
      '/me',
      options: Options(extra: {'__suppressSessionExpired': true}),
    );

    if (response.statusCode != 200 ||
        response.data == null ||
        response.data['loggedIn'] != true) {
      return null;
    }

    final userJson = response.data['user'] as Map<String, dynamic>;
    return User.fromJson(userJson);
  }
}
