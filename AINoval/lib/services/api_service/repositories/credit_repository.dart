import '../../../models/user_credit.dart';

/// 用户积分仓库接口
abstract interface class CreditRepository {
  /// 获取当前用户的积分余额
  Future<UserCredit> getUserCredits();
} 