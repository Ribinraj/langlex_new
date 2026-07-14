import 'package:dio/dio.dart';
import 'package:langlex_new_app/core/api_exception.dart';
import 'package:langlex_new_app/core/urls.dart';

class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createOrder({required int planId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.createPaymentOrder,
        data: {'plan_id': planId},
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> verifyPayment({required int orderId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.verifyPayment,
        data: {'order_id': orderId, 'mock_status': 'success'},
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> getMySubscription() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.mySubscription,
      );
      return response.data?['subscription'] as Map<String, dynamic>? ?? {};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
