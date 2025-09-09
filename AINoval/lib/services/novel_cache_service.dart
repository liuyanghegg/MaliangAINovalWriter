import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/novel_structure.dart';
import '../utils/logger.dart';

/// 小说缓存服务
/// 提供小说本地缓存、阅读进度管理等功能
class NovelCacheService {
  static const String _cacheDirectoryName = 'novel_cache';
  static const String _readingProgressKey = 'reading_progress';
  static const String _novelMetadataPrefix = 'novel_metadata_';
  
  // 单例模式
  static final NovelCacheService _instance = NovelCacheService._internal();
  factory NovelCacheService() => _instance;
  NovelCacheService._internal();
  
  // 缓存目录
  Directory? _cacheDirectory;
  
  /// 初始化缓存服务
  Future<void> init() async {
    try {
      _cacheDirectory = await getNovelCacheDirectory();
      await _cacheDirectory!.create(recursive: true);
      AppLogger.i('NovelCacheService', '缓存服务初始化完成: ${_cacheDirectory!.path}');
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '缓存服务初始化失败', e, stackTrace);
    }
  }
  
  /// 获取小说缓存目录
  Future<Directory> getNovelCacheDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory('${appDocDir.path}/$_cacheDirectoryName');
  }
  
  /// 保存完整小说数据到本地缓存
  Future<void> saveCompleteNovel(Novel novel) async {
    try {
      if (_cacheDirectory == null) {
        await init();
      }
      
      final file = File('${_cacheDirectory!.path}/novel_${novel.id}.json');
      final jsonData = json.encode(novel.toJson());
      
      await file.writeAsString(jsonData);
      
      // 保存小说元数据（包括服务器更新时间）
      await _saveNovelMetadata(novel.id, {
        'serverUpdatedAt': novel.updatedAt.toIso8601String(),
        'isCached': true,
        'cachedAt': DateTime.now().toIso8601String(),
      });
      
      AppLogger.i('NovelCacheService', '完整小说缓存保存成功: ${novel.id}');
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '保存完整小说缓存失败: ${novel.id}', e, stackTrace);
      rethrow;
    }
  }
  
  /// 从本地缓存读取完整小说数据
  Future<Novel?> getCompleteNovel(String novelId) async {
    try {
      if (_cacheDirectory == null) {
        await init();
      }
      
      final file = File('${_cacheDirectory!.path}/novel_$novelId.json');
      
      if (!await file.exists()) {
        AppLogger.v('NovelCacheService', '小说缓存文件不存在: $novelId');
        return null;
      }
      
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      final novel = Novel.fromJson(jsonData);
      AppLogger.v('NovelCacheService', '成功读取缓存小说: $novelId');
      return novel;
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '读取缓存小说失败: $novelId', e, stackTrace);
      return null;
    }
  }
  
  /// 获取缓存的小说服务器更新时间
  Future<DateTime?> getCachedNovelServerUpdatedAt(String novelId) async {
    try {
      final metadata = await _getNovelMetadata(novelId);
      if (metadata?['serverUpdatedAt'] != null) {
        return DateTime.parse(metadata!['serverUpdatedAt']);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '获取缓存小说服务器更新时间失败: $novelId', e, stackTrace);
      return null;
    }
  }
  
  /// 标记小说是否已完整缓存
  Future<void> markNovelAsFullyCached(String novelId, bool isFullyCached) async {
    try {
      final metadata = await _getNovelMetadata(novelId) ?? {};
      metadata['isCached'] = isFullyCached;
      metadata['lastUpdated'] = DateTime.now().toIso8601String();
      await _saveNovelMetadata(novelId, metadata);
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '标记小说缓存状态失败: $novelId', e, stackTrace);
    }
  }
  
  /// 检查小说是否已完整缓存
  Future<bool> isNovelFullyCached(String novelId) async {
    try {
      final metadata = await _getNovelMetadata(novelId);
      return metadata?['isCached'] == true;
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '检查小说缓存状态失败: $novelId', e, stackTrace);
      return false;
    }
  }
  
  /// 保存阅读进度
  Future<void> saveReadingProgress(
    String novelId, 
    String chapterId, 
    int pageIndex, 
    DateTime readTime
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = {
        'lastReadChapterId': chapterId,
        'lastReadPageIndex': pageIndex,
        'lastReadTime': readTime.toIso8601String(),
      };
      
      await prefs.setString(
        '${_readingProgressKey}_$novelId', 
        json.encode(progressData)
      );
      
      AppLogger.v('NovelCacheService', 
          '保存阅读进度: $novelId - 章节: $chapterId, 页面: $pageIndex');
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '保存阅读进度失败: $novelId', e, stackTrace);
    }
  }
  
  /// 获取阅读进度
  Future<Map<String, dynamic>?> getReadingProgress(String novelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressString = prefs.getString('${_readingProgressKey}_$novelId');
      
      if (progressString != null) {
        final progressData = json.decode(progressString) as Map<String, dynamic>;
        AppLogger.v('NovelCacheService', '获取阅读进度: $novelId - $progressData');
        return progressData;
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '获取阅读进度失败: $novelId', e, stackTrace);
      return null;
    }
  }
  
  /// 获取所有小说的阅读进度
  Future<Map<String, Map<String, dynamic>>> getAllReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final progressMap = <String, Map<String, dynamic>>{};
      
      for (final key in allKeys) {
        if (key.startsWith(_readingProgressKey)) {
          final novelId = key.substring('${_readingProgressKey}_'.length);
          final progressString = prefs.getString(key);
          if (progressString != null) {
            final progressData = json.decode(progressString) as Map<String, dynamic>;
            progressMap[novelId] = progressData;
          }
        }
      }
      
      return progressMap;
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '获取所有阅读进度失败', e, stackTrace);
      return {};
    }
  }
  
  /// 清除单个小说的缓存
  Future<void> clearNovelCache(String novelId) async {
    try {
      if (_cacheDirectory == null) {
        await init();
      }
      
      final file = File('${_cacheDirectory!.path}/novel_$novelId.json');
      if (await file.exists()) {
        await file.delete();
      }
      
      // 清除元数据
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_novelMetadataPrefix$novelId');
      
      AppLogger.i('NovelCacheService', '清除小说缓存: $novelId');
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '清除小说缓存失败: $novelId', e, stackTrace);
    }
  }
  
  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      if (_cacheDirectory == null) {
        await init();
      }
      
      // 删除所有缓存文件
      if (await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      }
      
      // 清除所有元数据和阅读进度
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (key.startsWith(_novelMetadataPrefix) || 
            key.startsWith(_readingProgressKey)) {
          await prefs.remove(key);
        }
      }
      
      AppLogger.i('NovelCacheService', '清除所有缓存完成');
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '清除所有缓存失败', e, stackTrace);
    }
  }
  
  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      if (_cacheDirectory == null) {
        await init();
      }
      
      final files = await _cacheDirectory!.list().toList();
      final novelFiles = files.where((f) => f.path.contains('novel_')).toList();
      
      int totalSize = 0;
      for (final file in novelFiles) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      return {
        'cachedNovelsCount': novelFiles.length,
        'totalCacheSize': totalSize,
        'cacheDirectory': _cacheDirectory!.path,
      };
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '获取缓存统计信息失败', e, stackTrace);
      return {
        'cachedNovelsCount': 0,
        'totalCacheSize': 0,
        'cacheDirectory': '',
      };
    }
  }
  
  /// 保存小说元数据
  Future<void> _saveNovelMetadata(String novelId, Map<String, dynamic> metadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_novelMetadataPrefix$novelId', 
        json.encode(metadata)
      );
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '保存小说元数据失败: $novelId', e, stackTrace);
    }
  }
  
  /// 获取小说元数据
  Future<Map<String, dynamic>?> getCacheMetadata(String novelId) async {
    return _getNovelMetadata(novelId);
  }
  
  /// 获取小说元数据（私有方法）
  Future<Map<String, dynamic>?> _getNovelMetadata(String novelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataString = prefs.getString('$_novelMetadataPrefix$novelId');
      
      if (metadataString != null) {
        return json.decode(metadataString) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('NovelCacheService', '获取小说元数据失败: $novelId', e, stackTrace);
      return null;
    }
  }
} 