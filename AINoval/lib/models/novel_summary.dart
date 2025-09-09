import 'package:equatable/equatable.dart';
import 'novel_structure.dart';

class NovelSummary extends Equatable {
  
  const NovelSummary({
    required this.id,
    required this.title,
    this.coverUrl = '',
    required this.lastEditTime,
    this.wordCount = 0,
    this.readTime = 0,
    this.version = 1,
    this.seriesName = '',
    this.completionPercentage = 0.0,
    this.lastEditedChapterId,
    this.author,
    this.contributors = const [],
    this.actCount = 0,
    this.chapterCount = 0,
    this.sceneCount = 0,
    this.description = '',
    required this.serverUpdatedAt,
    this.localUpdatedAt,
    this.isCached = false,
    this.needsSync = false,
    this.lastReadTime,
  });
  
  // 从JSON转换方法
  factory NovelSummary.fromJson(Map<String, dynamic> json) {
    return NovelSummary(
      id: json['id'],
      title: json['title'],
      coverUrl: json['coverUrl'] ?? '',
      lastEditTime: DateTime.parse(json['lastEditTime']),
      wordCount: json['wordCount'] ?? 0,
      readTime: json['readTime'] ?? 0,
      version: json['version'] ?? 1,
      seriesName: json['seriesName'] ?? '',
      completionPercentage: json['completionPercentage']?.toDouble() ?? 0.0,
      lastEditedChapterId: json['lastEditedChapterId'],
      author: json['author'],
      contributors: (json['contributors'] as List?)?.cast<String>() ?? const [],
      actCount: json['actCount'] ?? 0,
      chapterCount: json['chapterCount'] ?? 0,
      sceneCount: json['sceneCount'] ?? 0,
      description: json['description'] ?? '',
      serverUpdatedAt: json['serverUpdatedAt'] != null 
          ? DateTime.parse(json['serverUpdatedAt'])
          : DateTime.parse(json['lastEditTime']),
      localUpdatedAt: json['localUpdatedAt'] != null 
          ? DateTime.parse(json['localUpdatedAt']) 
          : null,
      isCached: json['isCached'] ?? false,
      needsSync: json['needsSync'] ?? false,
      lastReadTime: json['lastReadTime'] != null 
          ? DateTime.parse(json['lastReadTime']) 
          : null,
    );
  }
  
  // 从Novel对象转换方法
  factory NovelSummary.fromNovel(Novel novel) {
    return NovelSummary(
      id: novel.id,
      title: novel.title,
      coverUrl: novel.coverUrl,
      lastEditTime: novel.updatedAt,
      wordCount: novel.wordCount,
      readTime: novel.readTime,
      version: novel.version,
      seriesName: '', // Novel中没有seriesName字段，使用空字符串
      completionPercentage: 0.0, // 需要计算的字段，暂时设为0
      lastEditedChapterId: novel.lastEditedChapterId,
      author: novel.author?.username,
      contributors: novel.contributors,
      actCount: novel.getActCount(),
      chapterCount: novel.getChapterCount(), 
      sceneCount: novel.getSceneCount(),
      description: '', // Novel中没有description字段，使用空字符串
      serverUpdatedAt: novel.updatedAt,
      localUpdatedAt: null, // 初始时本地缓存时间为空
      isCached: false, // 初始时未缓存
      needsSync: false, // 初始时不需要同步
      lastReadTime: null, // 初始时没有阅读时间
    );
  }
  final String id;
  final String title;
  final String coverUrl;
  final DateTime lastEditTime;
  final int wordCount;
  final int readTime; // 估计阅读时间（分钟）
  final int version; // 文档版本号
  final String seriesName;
  final double completionPercentage;
  final String? lastEditedChapterId;
  final String? author;
  final List<String> contributors; // 贡献者列表
  final int actCount;
  final int chapterCount;
  final int sceneCount;
  final String description; // 小说描述
  
  final DateTime serverUpdatedAt; // 服务器端最新更新时间
  final DateTime? localUpdatedAt; // 本地缓存的更新时间
  final bool isCached; // 是否已在本地完整缓存
  final bool needsSync; // 是否需要同步
  final DateTime? lastReadTime; // 上次阅读时间
  
  @override
  List<Object?> get props => [
    id, 
    title, 
    coverUrl,
    lastEditTime, 
    wordCount, 
    readTime,
    version,
    seriesName, 
    completionPercentage,
    lastEditedChapterId,
    author,
    contributors,
    actCount,
    chapterCount,
    sceneCount,
    description,
    serverUpdatedAt,
    localUpdatedAt,
    isCached,
    needsSync,
    lastReadTime,
  ];
  
  // 转换为JSON方法
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'lastEditTime': lastEditTime.toIso8601String(),
      'wordCount': wordCount,
      'readTime': readTime,
      'version': version,
      'seriesName': seriesName,
      'completionPercentage': completionPercentage,
      'lastEditedChapterId': lastEditedChapterId,
      'author': author,
      'contributors': contributors,
      'actCount': actCount,
      'chapterCount': chapterCount,
      'sceneCount': sceneCount,
      'description': description,
      'serverUpdatedAt': serverUpdatedAt.toIso8601String(),
      'localUpdatedAt': localUpdatedAt?.toIso8601String(),
      'isCached': isCached,
      'needsSync': needsSync,
      'lastReadTime': lastReadTime?.toIso8601String(),
    };
  }
  
  // 新增 copyWith 方法，方便状态更新
  NovelSummary copyWith({
    String? id,
    String? title,
    String? coverUrl,
    DateTime? lastEditTime,
    int? wordCount,
    int? readTime,
    int? version,
    String? seriesName,
    double? completionPercentage,
    String? lastEditedChapterId,
    String? author,
    List<String>? contributors,
    int? actCount,
    int? chapterCount,
    int? sceneCount,
    String? description,
    DateTime? serverUpdatedAt,
    DateTime? localUpdatedAt,
    bool? isCached,
    bool? needsSync,
    DateTime? lastReadTime,
  }) {
    return NovelSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      lastEditTime: lastEditTime ?? this.lastEditTime,
      wordCount: wordCount ?? this.wordCount,
      readTime: readTime ?? this.readTime,
      version: version ?? this.version,
      seriesName: seriesName ?? this.seriesName,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      lastEditedChapterId: lastEditedChapterId ?? this.lastEditedChapterId,
      author: author ?? this.author,
      contributors: contributors ?? this.contributors,
      actCount: actCount ?? this.actCount,
      chapterCount: chapterCount ?? this.chapterCount,
      sceneCount: sceneCount ?? this.sceneCount,
      description: description ?? this.description,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      isCached: isCached ?? this.isCached,
      needsSync: needsSync ?? this.needsSync,
      lastReadTime: lastReadTime ?? this.lastReadTime,
    );
  }
} 