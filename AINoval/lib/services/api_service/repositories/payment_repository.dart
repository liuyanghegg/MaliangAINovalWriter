import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/utils/logger.dart';

enum PayChannel { wechat, alipay }

class PaymentOrderDto {
  final String id;
  final String outTradeNo;
  final String planId;
  final String paymentUrl;
  final String status;
  PaymentOrderDto({
    required this.id,
    required this.outTradeNo,
    required this.planId,
    required this.paymentUrl,
    required this.status,
  });

  factory PaymentOrderDto.fromJson(Map<String, dynamic> json) => PaymentOrderDto(
        id: json['id'] ?? '',
        outTradeNo: json['outTradeNo'] ?? '',
        planId: json['planId'] ?? '',
        paymentUrl: json['paymentUrl'] ?? '',
        status: json['status']?.toString() ?? '',
      );
}

class PaymentRepository {
  final ApiClient _apiClient;
  final String _tag = 'PaymentRepository';

  PaymentRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<PaymentOrderDto> createPayment({
    required String planId,
    required PayChannel channel,
  }) async {
    try {
      final res = await _apiClient.post('/payments/create/$planId?channel=${channel.name.toUpperCase()}');
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        return PaymentOrderDto.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception('创建支付订单失败');
    } catch (e) {
      AppLogger.e(_tag, '创建支付订单失败', e);
      rethrow;
    }
  }

  Future<PaymentOrderDto> createCreditPackPayment({
    required String planId,
    required PayChannel channel,
  }) async {
    try {
      final res = await _apiClient.post('/payments/create-credit-pack/$planId?channel=${channel.name.toUpperCase()}');
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        return PaymentOrderDto.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception('创建积分包支付订单失败');
    } catch (e) {
      AppLogger.e(_tag, '创建积分包支付订单失败', e);
      rethrow;
    }
  }

  Future<List<PaymentOrderDto>> myOrders() async {
    try {
      final res = await _apiClient.get('/payments/my-orders');
      if (res is List) {
        return res.map((e) => PaymentOrderDto.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.e(_tag, '获取我的订单失败', e);
      return [];
    }
  }
}


