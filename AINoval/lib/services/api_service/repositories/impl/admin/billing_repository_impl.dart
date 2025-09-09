import 'package:ainoval/models/admin/billing_models.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';

class BillingRepositoryImpl {
  final ApiClient apiClient;

  BillingRepositoryImpl({required this.apiClient});

  Future<List<CreditTransactionModel>> listTransactions({int page = 0, int size = 20, String? status, String? userId}) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null && status.isNotEmpty) 'status': status,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    final data = await apiClient.getWithParams('/admin/billing/transactions', queryParameters: params);
    if (data is List) {
      return data.map((e) => CreditTransactionModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<int> countTransactions({String? status, String? userId}) async {
    final params = <String, dynamic>{
      if (status != null && status.isNotEmpty) 'status': status,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    final data = await apiClient.getWithParams('/admin/billing/transactions/count', queryParameters: params);
    if (data is int) return data;
    if (data is String) return int.tryParse(data) ?? 0;
    if (data is Map<String, dynamic> && data['count'] is int) return data['count'] as int;
    return 0;
  }

  Future<CreditTransactionModel?> getTransaction(String traceId) async {
    final data = await apiClient.get('/admin/billing/transactions/$traceId');
    if (data is Map<String, dynamic>) {
      return CreditTransactionModel.fromJson(data);
    }
    return null;
  }

  Future<CreditTransactionModel?> reverse(String traceId, {required String operatorUserId, required String reason}) async {
    final payload = {'operatorUserId': operatorUserId, 'reason': reason};
    final data = await apiClient.post('/admin/billing/transactions/$traceId/reverse', data: payload);
    if (data is Map<String, dynamic>) {
      return CreditTransactionModel.fromJson(data);
    }
    return null;
  }
}


