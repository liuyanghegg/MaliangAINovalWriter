import '../../../../models/user_credit.dart';
import '../../../../utils/logger.dart';
import '../../base/api_client.dart';
import '../credit_repository.dart';

/// 用户积分仓库实现
class CreditRepositoryImpl implements CreditRepository {
  final ApiClient _apiClient;
  static const String _tag = 'CreditRepositoryImpl';

  CreditRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<UserCredit> getUserCredits() async {
    try {
      AppLogger.i(_tag, '获取用户积分余额');
      final rawData = await _apiClient.getUserCredits();
      
      // 转换为UserCredit对象
      final userCredit = UserCredit.fromJson(rawData);
      
      AppLogger.i(_tag, '获取用户积分余额成功: ${userCredit.credits}');
      return userCredit;
    } catch (e, stackTrace) {
      AppLogger.e(_tag, '获取用户积分余额失败', e, stackTrace);
      rethrow;
    }
  }
} 