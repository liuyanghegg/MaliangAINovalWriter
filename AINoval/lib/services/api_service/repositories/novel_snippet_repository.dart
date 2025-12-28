import 'package:ainoval/models/novel_snippet.dart';

/// 小说片段仓储接口
///
/// 定义与小说片段相关的所有API操作
abstract class NovelSnippetRepository {
  /// 创建片段
  /// 
  /// [request] 创建片段请求数据
  /// 返回创建的片段信息
  Future<NovelSnippet> createSnippet(CreateSnippetRequest request);

  /// 获取小说的所有片段（分页）
  /// 
  /// [novelId] 小说ID
  /// [page] 页码，默认为0
  /// [size] 每页大小，默认为20
  /// 返回分页片段数据
  Future<SnippetPageResult<NovelSnippet>> getSnippetsByNovelId(
    String novelId, {
    int page = 0,
    int size = 20,
  });

  /// 获取片段详情
  /// 
  /// [snippetId] 片段ID
  /// 返回片段详细信息（会增加浏览次数）
  Future<NovelSnippet> getSnippetDetail(String snippetId);

  /// 更新片段内容
  /// 
  /// [request] 更新内容请求数据
  /// 返回更新后的片段信息
  Future<NovelSnippet> updateSnippetContent(UpdateSnippetContentRequest request);

  /// 更新片段标题
  /// 
  /// [request] 更新标题请求数据
  /// 返回更新后的片段信息
  Future<NovelSnippet> updateSnippetTitle(UpdateSnippetTitleRequest request);

  /// 收藏/取消收藏片段
  /// 
  /// [request] 更新收藏状态请求数据
  /// 返回更新后的片段信息
  Future<NovelSnippet> updateSnippetFavorite(UpdateSnippetFavoriteRequest request);

  /// 获取片段历史记录
  /// 
  /// [snippetId] 片段ID
  /// [page] 页码，默认为0
  /// [size] 每页大小，默认为10
  /// 返回分页历史记录数据
  Future<SnippetPageResult<NovelSnippetHistory>> getSnippetHistory(
    String snippetId, {
    int page = 0,
    int size = 10,
  });

  /// 预览历史版本内容
  /// 
  /// [snippetId] 片段ID
  /// [version] 版本号
  /// 返回指定版本的历史记录
  Future<NovelSnippetHistory> previewHistoryVersion(String snippetId, int version);

  /// 回退到历史版本（创建新片段）
  /// 
  /// [request] 回退版本请求数据
  /// 返回新创建的片段信息
  Future<NovelSnippet> revertToHistoryVersion(RevertSnippetVersionRequest request);

  /// 删除片段
  /// 
  /// [snippetId] 片段ID
  /// 执行软删除操作
  Future<void> deleteSnippet(String snippetId);

  /// 获取用户收藏的片段
  /// 
  /// [page] 页码，默认为0
  /// [size] 每页大小，默认为20
  /// 返回分页收藏片段数据
  Future<SnippetPageResult<NovelSnippet>> getFavoriteSnippets({
    int page = 0,
    int size = 20,
  });

  /// 搜索片段
  /// 
  /// [novelId] 小说ID
  /// [searchText] 搜索文本
  /// [page] 页码，默认为0
  /// [size] 每页大小，默认为20
  /// 返回搜索结果分页数据
  Future<SnippetPageResult<NovelSnippet>> searchSnippets(
    String novelId,
    String searchText, {
    int page = 0,
    int size = 20,
  });
} 