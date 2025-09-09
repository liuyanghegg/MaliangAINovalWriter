import 'admin_repository_impl.dart';
import '../../base/api_client.dart';
import '../../base/api_exception.dart';
import '../../../../models/prompt_models.dart';
import '../../../../utils/logger.dart';

extension PromptTemplateExtraApis on AdminRepositoryImpl {
  static const String _tag = 'AdminRepository(Extra)';

  /// 获取待审核模板列表
  Future<List<PromptTemplate>> getPendingTemplates() async {
    try {
      AppLogger.d(_tag, '🔍 获取待审核模板列表');
      final api = ApiClient();
      final response = await api.get('/admin/prompt-templates/pending');

      final data = (response is Map<String, dynamic>) ? (response['data'] ?? response) : response;
      if (data is List) {
        AppLogger.d(_tag, '✅ 获取待审核模板列表成功: count=${data.length}');
        return data.map((json) => PromptTemplate.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ApiException(-1, '待审核模板列表响应格式错误');
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取待审核模板列表失败', e);
      rethrow;
    }
  }

  /// 获取官方认证模板列表
  Future<List<PromptTemplate>> getVerifiedTemplates() async {
    try {
      AppLogger.d(_tag, '🔍 获取官方认证模板列表');
      final api = ApiClient();
      final response = await api.get('/admin/prompt-templates/verified');

      final data = (response is Map<String, dynamic>) ? (response['data'] ?? response) : response;
      if (data is List) {
        AppLogger.d(_tag, '✅ 获取官方认证模板列表成功: count=${data.length}');
        return data.map((json) => PromptTemplate.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ApiException(-1, '官方认证模板列表响应格式错误');
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取官方认证模板列表失败', e);
      rethrow;
    }
  }

  /// 获取所有用户模板列表（包括私有和公共）
  Future<List<PromptTemplate>> getAllUserTemplates({
    int page = 0,
    int size = 20,
    String? search,
  }) async {
    try {
      AppLogger.d(_tag, '🔍 获取所有用户模板列表: page=$page, size=$size, search=$search');
      
      String path = '/admin/prompt-templates/all-user?page=$page&size=$size';
      if (search != null && search.isNotEmpty) {
        path += '&search=${Uri.encodeComponent(search)}';
      }
      
      final api = ApiClient();
      final response = await api.get(path);

      final data = (response is Map<String, dynamic>) ? (response['data'] ?? response) : response;
      if (data is List) {
        AppLogger.d(_tag, '✅ 获取所有用户模板列表成功: count=${data.length}');
        return data.map((json) => PromptTemplate.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic> && data.containsKey('content')) {
        // 处理分页响应
        final content = data['content'] as List;
        AppLogger.d(_tag, '✅ 获取所有用户模板列表成功(分页): count=${content.length}');
        return content.map((json) => PromptTemplate.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ApiException(-1, '所有用户模板列表响应格式错误');
    } catch (e) {
      AppLogger.e(_tag, '❌ 获取所有用户模板列表失败', e);
      rethrow;
    }
  }

  /// 更新模板
  Future<PromptTemplate> updateTemplate(String templateId, PromptTemplate template) async {
    try {
      AppLogger.d(_tag, '🔄 更新模板: templateId=$templateId, name=${template.name}');
      
      final api = ApiClient();
      final response = await api.put('/admin/prompt-templates/$templateId', data: template.toJson());

      final data = (response is Map<String, dynamic>) ? (response['data'] ?? response) : response;
      if (data is Map<String, dynamic>) {
        AppLogger.d(_tag, '✅ 更新模板成功: ${template.name}');
        return PromptTemplate.fromJson(data);
      }
      throw ApiException(-1, '更新模板响应格式错误');
    } catch (e) {
      AppLogger.e(_tag, '❌ 更新模板失败', e);
      rethrow;
    }
  }
} 