import '../../../../models/public_model_config.dart';
import '../../../../utils/logger.dart';
import '../../base/api_client.dart';
import '../public_model_repository.dart';

/// 公共模型仓库实现
class PublicModelRepositoryImpl implements PublicModelRepository {
  final ApiClient _apiClient;
  static const String _tag = 'PublicModelRepositoryImpl';

  PublicModelRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<PublicModel>> getPublicModels() async {
    try {
      AppLogger.i(_tag, '获取公共模型列表');
      final rawList = await _apiClient.getPublicModels();
      
      final models = rawList.map((json) {
        try {
          return PublicModel.fromJson(json);
        } catch (e) {
          AppLogger.e(_tag, '解析公共模型数据失败', e);
          AppLogger.d(_tag, '问题数据: $json');
          // 跳过解析失败的模型，继续处理其他模型
          return null;
        }
      }).whereType<PublicModel>().toList();
      
      AppLogger.i(_tag, '获取公共模型列表成功: 共${models.length}个模型');
      return models;
    } catch (e, stackTrace) {
      AppLogger.e(_tag, '获取公共模型列表失败', e, stackTrace);
      rethrow;
    }
  }
} 