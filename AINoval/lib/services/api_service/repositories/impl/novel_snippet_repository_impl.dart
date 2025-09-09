import 'package:ainoval/models/novel_snippet.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/repositories/novel_snippet_repository.dart';
import 'package:ainoval/utils/logger.dart';

/// 小说片段仓储实现类
///
/// 使用ApiClient调用后端API实现片段相关操作
class NovelSnippetRepositoryImpl implements NovelSnippetRepository {
  final ApiClient _apiClient;

  NovelSnippetRepositoryImpl(this._apiClient);

  @override
  Future<NovelSnippet> createSnippet(CreateSnippetRequest request) async {
    try {
      AppLogger.i('NovelSnippetRepository', '创建片段: ${request.title}');
      
      final response = await _apiClient.createSnippet(request.toJson());
      
      if (response is Map<String, dynamic>) {
        return NovelSnippet.fromJson(response);
      } else {
        throw Exception('创建片段响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '创建片段失败', e);
      rethrow;
    }
  }

  @override
  Future<SnippetPageResult<NovelSnippet>> getSnippetsByNovelId(
    String novelId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      AppLogger.d('NovelSnippetRepository', '获取小说片段列表: novelId=$novelId, page=$page, size=$size');
      
      final response = await _apiClient.getSnippetsByNovelId(novelId, page: page, size: size);
      
      if (response is Map<String, dynamic>) {
        return SnippetPageResult.fromJson(
          response,
          (json) => NovelSnippet.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('获取片段列表响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '获取小说片段列表失败: novelId=$novelId', e);
      rethrow;
    }
  }

  @override
  Future<NovelSnippet> getSnippetDetail(String snippetId) async {
    try {
      AppLogger.d('NovelSnippetRepository', '获取片段详情: snippetId=$snippetId');
      
      final response = await _apiClient.getSnippetDetail(snippetId);
      
      if (response is Map<String, dynamic>) {
        return NovelSnippet.fromJson(response);
      } else {
        throw Exception('获取片段详情响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '获取片段详情失败: snippetId=$snippetId', e);
      rethrow;
    }
  }

  @override
  Future<NovelSnippet> updateSnippetContent(UpdateSnippetContentRequest request) async {
    try {
      AppLogger.i('NovelSnippetRepository', '更新片段内容: snippetId=${request.snippetId}');
      
      final response = await _apiClient.updateSnippetContent(request.toJson());
      
      if (response is Map<String, dynamic>) {
        return NovelSnippet.fromJson(response);
      } else {
        throw Exception('更新片段内容响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '更新片段内容失败: snippetId=${request.snippetId}', e);
      rethrow;
    }
  }

  @override
  Future<NovelSnippet> updateSnippetTitle(UpdateSnippetTitleRequest request) async {
    try {
      AppLogger.i('NovelSnippetRepository', '更新片段标题: snippetId=${request.snippetId}');
      
      final response = await _apiClient.updateSnippetTitle(request.toJson());
      
      if (response is Map<String, dynamic>) {
        return NovelSnippet.fromJson(response);
      } else {
        throw Exception('更新片段标题响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '更新片段标题失败: snippetId=${request.snippetId}', e);
      rethrow;
    }
  }

  @override
  Future<NovelSnippet> updateSnippetFavorite(UpdateSnippetFavoriteRequest request) async {
    try {
      AppLogger.i('NovelSnippetRepository', '更新片段收藏状态: snippetId=${request.snippetId}, isFavorite=${request.isFavorite}');
      
      final response = await _apiClient.updateSnippetFavorite(request.toJson());
      
      if (response is Map<String, dynamic>) {
        return NovelSnippet.fromJson(response);
      } else {
        throw Exception('更新片段收藏状态响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '更新片段收藏状态失败: snippetId=${request.snippetId}', e);
      rethrow;
    }
  }

  @override
  Future<SnippetPageResult<NovelSnippetHistory>> getSnippetHistory(
    String snippetId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      AppLogger.d('NovelSnippetRepository', '获取片段历史记录: snippetId=$snippetId, page=$page, size=$size');
      
      final response = await _apiClient.getSnippetHistory(snippetId, page: page, size: size);
      
      if (response is Map<String, dynamic>) {
        return SnippetPageResult.fromJson(
          response,
          (json) => NovelSnippetHistory.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('获取片段历史记录响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '获取片段历史记录失败: snippetId=$snippetId', e);
      rethrow;
    }
  }

  @override
  Future<NovelSnippetHistory> previewHistoryVersion(String snippetId, int version) async {
    try {
      AppLogger.d('NovelSnippetRepository', '预览历史版本: snippetId=$snippetId, version=$version');
      
      final response = await _apiClient.previewSnippetHistoryVersion(snippetId, version);
      
      if (response is Map<String, dynamic>) {
        return NovelSnippetHistory.fromJson(response);
      } else {
        throw Exception('预览历史版本响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '预览历史版本失败: snippetId=$snippetId, version=$version', e);
      rethrow;
    }
  }

  @override
  Future<NovelSnippet> revertToHistoryVersion(RevertSnippetVersionRequest request) async {
    try {
      AppLogger.i('NovelSnippetRepository', '回退到历史版本: snippetId=${request.snippetId}, version=${request.version}');
      
      final response = await _apiClient.revertSnippetToVersion(request.toJson());
      
      if (response is Map<String, dynamic>) {
        return NovelSnippet.fromJson(response);
      } else {
        throw Exception('回退到历史版本响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '回退到历史版本失败: snippetId=${request.snippetId}, version=${request.version}', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteSnippet(String snippetId) async {
    try {
      AppLogger.i('NovelSnippetRepository', '删除片段: snippetId=$snippetId');
      
      await _apiClient.deleteSnippet(snippetId);
      
      AppLogger.i('NovelSnippetRepository', '片段删除成功: snippetId=$snippetId');
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '删除片段失败: snippetId=$snippetId', e);
      rethrow;
    }
  }

  @override
  Future<SnippetPageResult<NovelSnippet>> getFavoriteSnippets({
    int page = 0,
    int size = 20,
  }) async {
    try {
      AppLogger.d('NovelSnippetRepository', '获取收藏片段: page=$page, size=$size');
      
      final response = await _apiClient.getFavoriteSnippets(page: page, size: size);
      
      if (response is Map<String, dynamic>) {
        return SnippetPageResult.fromJson(
          response,
          (json) => NovelSnippet.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('获取收藏片段响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '获取收藏片段失败', e);
      rethrow;
    }
  }

  @override
  Future<SnippetPageResult<NovelSnippet>> searchSnippets(
    String novelId,
    String searchText, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      AppLogger.d('NovelSnippetRepository', '搜索片段: novelId=$novelId, searchText=$searchText, page=$page, size=$size');
      
      final response = await _apiClient.searchSnippets(novelId, searchText, page: page, size: size);
      
      if (response is Map<String, dynamic>) {
        return SnippetPageResult.fromJson(
          response,
          (json) => NovelSnippet.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('搜索片段响应格式错误: $response');
      }
    } catch (e) {
      AppLogger.e('NovelSnippetRepository', '搜索片段失败: novelId=$novelId, searchText=$searchText', e);
      rethrow;
    }
  }
} 