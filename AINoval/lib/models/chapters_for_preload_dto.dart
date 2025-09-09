import 'novel_structure.dart';

/// 预加载章节数据传输对象
/// 专门用于阅读器预加载功能，包含章节列表和对应的场景内容
class ChaptersForPreloadDto {
  const ChaptersForPreloadDto({
    required this.chapters,
    required this.scenesByChapter,
  });

  /// 从JSON创建实例
  factory ChaptersForPreloadDto.fromJson(Map<String, dynamic> json) {
    // 解析章节列表
    final List<Chapter> chaptersList = [];
    if (json['chapters'] != null && json['chapters'] is List) {
      chaptersList.addAll(
        (json['chapters'] as List<dynamic>)
            .map((chapterJson) => Chapter.fromJson(chapterJson as Map<String, dynamic>))
            .toList(),
      );
    }

    // 解析按章节分组的场景
    final Map<String, List<Scene>> scenesMap = {};
    if (json['scenesByChapter'] != null && json['scenesByChapter'] is Map) {
      final rawScenesMap = json['scenesByChapter'] as Map<String, dynamic>;
      for (final entry in rawScenesMap.entries) {
        final chapterId = entry.key;
        final scenesList = <Scene>[];
        
        if (entry.value is List) {
          scenesList.addAll(
            (entry.value as List<dynamic>)
                .map((sceneJson) => Scene.fromJson(sceneJson as Map<String, dynamic>))
                .toList(),
          );
        }
        
        scenesMap[chapterId] = scenesList;
      }
    }

    return ChaptersForPreloadDto(
      chapters: chaptersList,
      scenesByChapter: scenesMap,
    );
  }

  /// 章节列表，按顺序排列
  final List<Chapter> chapters;

  /// 按章节ID分组的场景列表
  /// Key: 章节ID
  /// Value: 该章节的场景列表（按sequence排序）
  final Map<String, List<Scene>> scenesByChapter;

  /// 获取章节总数
  int get chapterCount => chapters.length;

  /// 获取场景总数
  int get totalSceneCount {
    return scenesByChapter.values
        .map((scenes) => scenes.length)
        .fold(0, (sum, count) => sum + count);
  }

  /// 检查是否包含指定章节的数据
  bool containsChapter(String chapterId) {
    return chapters.any((chapter) => chapter.id == chapterId);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'scenesByChapter': scenesByChapter.map(
        (chapterId, scenes) => MapEntry(
          chapterId,
          scenes.map((scene) => scene.toJson()).toList(),
        ),
      ),
    };
  }

  @override
  String toString() {
    return 'ChaptersForPreloadDto(chapterCount: $chapterCount, totalSceneCount: $totalSceneCount)';
  }
} 