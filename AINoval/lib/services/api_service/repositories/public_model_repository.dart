import '../../../models/public_model_config.dart';

/// 公共模型仓库接口
abstract interface class PublicModelRepository {
  /// 获取公共模型列表
  /// 只包含向前端暴露的安全信息，不含API Keys等敏感数据
  /// 用户必须登录才能访问此接口
  Future<List<PublicModel>> getPublicModels();
} 