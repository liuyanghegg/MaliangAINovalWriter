import 'package:ainoval/models/import_status.dart';
import 'package:ainoval/models/novel_structure.dart';
import 'package:ainoval/models/scene_version.dart';
import 'package:ainoval/models/chapters_for_preload_dto.dart';

/// 小说仓库接口
///
/// 定义与小说相关的所有API操作
abstract class NovelRepository {
  /// 获取所有小说
  Future<List<Novel>> fetchNovels();

  /// 获取单个小说
  Future<Novel> fetchNovel(String id);

  /// 获取单个小说场景内容纯文本格式
  Future<Novel> fetchNovelText(String id);

  /// 获取单个小说
  Future<Novel> fetchNovelOnlyStructure(String id);

  /// 创建小说
  Future<Novel> createNovel(String title,
      {String? description, String? coverImage});

  /// 根据作者ID获取小说列表
  Future<List<Novel>> fetchNovelsByAuthor(String authorId);

  /// 搜索小说
  Future<List<Novel>> searchNovelsByTitle(String title);

  /// 删除小说
  Future<void> deleteNovel(String id);

  /// 获取场景内容
  Future<Scene> fetchSceneContent(
      String novelId, String actId, String chapterId, String sceneId);

  /// 更新场景内容
  Future<Scene> updateSceneContent(String novelId, String actId,
      String chapterId, String sceneId, Scene scene);

  /// 更新摘要内容
  Future<Summary> updateSummary(String novelId, String actId, String chapterId,
      String sceneId, Summary summary);

  /// 更新场景内容并保存历史版本
  Future<Scene> updateSceneContentWithHistory(String novelId, String chapterId,
      String sceneId, String content, String userId, String reason);

  /// 获取场景的历史版本列表
  Future<List<SceneHistoryEntry>> getSceneHistory(
      String novelId, String chapterId, String sceneId);

  /// 恢复场景到指定的历史版本
  Future<Scene> restoreSceneVersion(String novelId, String chapterId,
      String sceneId, int historyIndex, String userId, String reason);

  /// 对比两个场景版本
  Future<SceneVersionDiff> compareSceneVersions(String novelId,
      String chapterId, String sceneId, int versionIndex1, int versionIndex2);

  /// 导入小说文件（传统方式，向后兼容）
  ///
  /// 返回导入任务的ID
  Future<String> importNovel(List<int> fileBytes, String fileName);

  // === 新的三步导入流程方法 ===

  /// 第一步：上传文件获取预览会话ID
  ///
  /// - [fileBytes]: 文件字节数据
  /// - [fileName]: 文件名
  /// - 返回: 预览会话ID
  Future<String> uploadFileForPreview(List<int> fileBytes, String fileName);

  /// 第二步：获取导入预览
  ///
  /// - [fileSessionId]: 预览会话ID
  /// - [customTitle]: 自定义标题
  /// - [chapterLimit]: 章节数量限制
  /// - [enableSmartContext]: 是否启用智能上下文
  /// - [enableAISummary]: 是否启用AI摘要
  /// - [aiConfigId]: AI配置ID
  /// - [previewChapterCount]: 预览章节数量
  /// - 返回: 导入预览响应数据
  Future<Map<String, dynamic>> getImportPreview({
    required String fileSessionId,
    String? customTitle,
    int? chapterLimit,
    bool enableSmartContext = true,
    bool enableAISummary = false,
    String? aiConfigId,
    int previewChapterCount = 10,
  });

  /// 第三步：确认并开始导入
  ///
  /// - [previewSessionId]: 预览会话ID
  /// - [finalTitle]: 最终确认的标题
  /// - [selectedChapterIndexes]: 选中的章节索引列表
  /// - [enableSmartContext]: 是否启用智能上下文
  /// - [enableAISummary]: 是否启用AI摘要
  /// - [aiConfigId]: AI配置ID
  /// - 返回: 导入任务ID
  Future<String> confirmAndStartImport({
    required String previewSessionId,
    required String finalTitle,
    List<int>? selectedChapterIndexes,
    bool enableSmartContext = true,
    bool enableAISummary = false,
    String? aiConfigId,
  });

  /// 清理预览会话
  ///
  /// - [previewSessionId]: 预览会话ID
  Future<void> cleanupPreviewSession(String previewSessionId);

  /// 获取导入任务状态流
  ///
  /// 返回导入状态的实时更新
  Stream<ImportStatus> getImportStatus(String jobId);

  /// 取消导入任务
  ///
  /// - [jobId]: 导入任务ID
  /// - 返回: 是否成功取消
  Future<bool> cancelImport(String jobId);

  /// 获取当前章节后面指定数量的章节和场景内容
  ///
  /// 允许跨卷加载，专门用于阅读器的分批加载功能
  /// - [novelId]: 小说ID
  /// - [currentChapterId]: 当前章节ID
  /// - [chaptersLimit]: 要加载的章节数量，默认为3
  /// - 返回: 包含小说信息和后续章节场景数据的Novel对象
  Future<Novel?> fetchChaptersAfter(String novelId, String currentChapterId, {int chaptersLimit = 3, bool includeCurrentChapter = true});
  
  /// 获取指定章节后面的章节列表（用于预加载）
  ///
  /// 专门为预加载功能设计，只返回章节列表和场景内容，不返回完整小说结构
  /// - [novelId]: 小说ID
  /// - [currentChapterId]: 当前章节ID
  /// - [chaptersLimit]: 要获取的章节数量限制，默认为3
  /// - [includeCurrentChapter]: 是否包含当前章节，默认为false
  /// - 返回: 包含章节列表和场景数据的ChaptersForPreloadDto
  Future<ChaptersForPreloadDto?> fetchChaptersForPreload(
    String novelId,
    String currentChapterId, {
    int chaptersLimit = 3,
    bool includeCurrentChapter = false,
  });
}
