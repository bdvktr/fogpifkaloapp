import '../api_client.dart';
import '../models/admin_order.dart';
import '../models/admin_order_detail.dart';
import '../models/admin_reservation.dart';

class AdminRepository {
  final ApiClient apiClient;

  AdminRepository({required this.apiClient});

  Future<List<AdminOrder>> fetchOrders() async {
    final resp = await apiClient.dio.get('/admin/orders');

    if (resp.statusCode != 200) {
      throw Exception('Nem sikerült lekérdezni az admin rendeléseket.');
    }

    final data = resp.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Ismeretlen hiba a válaszban.');
    }

    final List<dynamic> list = (data['orders'] ?? []) as List<dynamic>;
    return list
        .map((e) => AdminOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminOrderDetail> fetchOrderDetail(int orderId) async {
    final resp = await apiClient.dio.get('/admin/orders/$orderId');

    if (resp.statusCode != 200) {
      throw Exception('Nem sikerült lekérdezni a rendelés részleteit.');
    }

    final data = resp.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Ismeretlen hiba a válaszban.');
    }

    return AdminOrderDetail.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final resp = await apiClient.dio.put(
      '/admin/orders/$orderId/status',
      data: {'status': status},
    );

    if (resp.statusCode != 200) {
      throw Exception('Nem sikerült frissíteni a rendelés státuszát.');
    }

    final data = resp.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Ismeretlen hiba a státusz frissítésnél.');
    }
  }

  Future<List<AdminReservation>> fetchReservations() async {
    final resp = await apiClient.dio.get('/admin/reservations');

    if (resp.statusCode != 200) {
      throw Exception('Nem sikerült lekérdezni a foglalásokat.');
    }

    final data = resp.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Ismeretlen hiba a válaszban.');
    }

    final List<dynamic> list = (data['reservations'] ?? []) as List<dynamic>;
    return list
        .map((e) => AdminReservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateReservationStatus(int reservationId, String status) async {
    final resp = await apiClient.dio.put(
      '/admin/reservations/$reservationId/status',
      data: {'status': status},
    );

    if (resp.statusCode != 200) {
      throw Exception('Nem sikerült frissíteni a foglalás státuszát.');
    }

    final data = resp.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Ismeretlen hiba a státusz frissítésnél.');
    }
  }
}