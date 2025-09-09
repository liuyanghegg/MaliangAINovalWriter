import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ainoval/models/novel_structure.dart';
import 'package:ainoval/services/api_service/repositories/novel_repository.dart';
import 'package:ainoval/services/api_service/repositories/editor_repository.dart';
import 'package:ainoval/utils/logger.dart';

/// 小说文件导出格式
enum NovelExportFormat {
  txt,      // 纯文本
  json,     // JSON格式(包含结构信息)
  markdown, // Markdown格式
}

/// 导出结果
class NovelExportResult {
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final NovelExportFormat format;
  final DateTime exportedAt;

  const NovelExportResult({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.format,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'format': format.name,
    'exportedAt': exportedAt.toIso8601String(),
  };

  factory NovelExportResult.fromJson(Map<String, dynamic> json) => NovelExportResult(
    filePath: json['filePath'],
    fileName: json['fileName'],
    fileSizeBytes: json['fileSizeBytes'],
    format: NovelExportFormat.values.firstWhere(
      (e) => e.name == json['format'],
      orElse: () => NovelExportFormat.txt,
    ),
    exportedAt: DateTime.parse(json['exportedAt']),
  );
}

/// 小说文件服务 - 处理小说内容的本地保存
class NovelFileService {
  final NovelRepository _novelRepository;
  final EditorRepository? _editorRepository;

  NovelFileService({
    required NovelRepository novelRepository,
    EditorRepository? editorRepository,
  }) : _novelRepository = novelRepository,
       _editorRepository = editorRepository;

  /// 获取小说存储目录
  Future<Directory> _getNovelStorageDirectory() async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Android: 使用外部存储的Documents目录
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        directory = Directory('${directory.path}/Documents/AINoval/Novels');
      } else {
        // 如果外部存储不可用，使用应用文档目录
        directory = await getApplicationDocumentsDirectory();
        directory = Directory('${directory.path}/Novels');
      }
    } else if (Platform.isIOS) {
      // iOS: 使用应用文档目录
      directory = await getApplicationDocumentsDirectory();
      directory = Directory('${directory.path}/Novels');
    } else {
      // 其他平台使用应用文档目录
      directory = await getApplicationDocumentsDirectory();
      directory = Directory('${directory.path}/Novels');
    }

    // 确保目录存在
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  /// 从后端获取完整小说内容
  Future<Novel> _fetchCompleteNovel(String novelId) async {
    try {
      AppLogger.i('NovelFileService', '开始获取完整小说内容: $novelId');
      
      // 优先尝试使用EditorRepository获取全部场景
      if (_editorRepository != null) {
        final novelWithAllScenes = await _editorRepository!.getNovelWithAllScenes(novelId);
        if (novelWithAllScenes != null) {
          AppLogger.i('NovelFileService', '通过EditorRepository获取完整小说成功');
          return novelWithAllScenes;
        }
      }
      
      // 回退到NovelRepository
      AppLogger.i('NovelFileService', '回退到NovelRepository获取小说基本信息');
      final novel = await _novelRepository.fetchNovel(novelId);
      
      // 逐个获取场景内容
      for (final act in novel.acts) {
        for (final chapter in act.chapters) {
          final List<Scene> scenesWithContent = [];
          
          for (final scene in chapter.scenes) {
            try {
              final sceneWithContent = await _novelRepository.fetchSceneContent(
                novelId, 
                act.id, 
                chapter.id, 
                scene.id
              );
              scenesWithContent.add(sceneWithContent);
            } catch (e) {
              AppLogger.w('NovelFileService', 
                '获取场景内容失败，使用默认内容: novelId=$novelId, sceneId=${scene.id}', e);
              scenesWithContent.add(scene);
            }
          }
          
          // 更新章节的场景列表
          chapter.scenes.clear();
          chapter.scenes.addAll(scenesWithContent);
        }
      }
      
      AppLogger.i('NovelFileService', '获取完整小说内容成功: ${novel.title}');
      return novel;
    } catch (e) {
      AppLogger.e('NovelFileService', '获取完整小说内容失败: $novelId', e);
      rethrow;
    }
  }

  /// 将小说导出为TXT格式
  String _exportToTxt(Novel novel) {
    final buffer = StringBuffer();
    
    // 标题和基本信息
    buffer.writeln('${novel.title}');
    buffer.writeln('${'=' * novel.title.length}');
    buffer.writeln();
    
    if (novel.author != null) {
      buffer.writeln('作者：${novel.author!.username}');
    }
    
    buffer.writeln('创建时间：${DateFormat('yyyy-MM-dd HH:mm').format(novel.createdAt)}');
    buffer.writeln('最后更新：${DateFormat('yyyy-MM-dd HH:mm').format(novel.updatedAt)}');
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln();

    // 内容
    for (final act in novel.acts) {
      // 幕标题
      buffer.writeln('${act.title}');
      buffer.writeln('${'*' * act.title.length}');
      buffer.writeln();
      
      for (final chapter in act.chapters) {
        // 章节标题
        buffer.writeln('${chapter.title}');
        buffer.writeln('${'-' * chapter.title.length}');
        buffer.writeln();
        
        for (final scene in chapter.scenes) {
          // 场景内容
          if (scene.content.isNotEmpty) {
            buffer.writeln(scene.content);
            buffer.writeln();
          }
          
          // 如果场景有摘要，也添加进去
          if (scene.summary != null && scene.summary!.content.isNotEmpty) {
            buffer.writeln('【场景摘要：${scene.summary!.content}】');
            buffer.writeln();
          }
        }
        
        buffer.writeln(); // 章节间空行
      }
      
      buffer.writeln(); // 幕间空行
    }

    return buffer.toString();
  }

  /// 将小说导出为Markdown格式
  String _exportToMarkdown(Novel novel) {
    final buffer = StringBuffer();
    
    // 标题和基本信息
    buffer.writeln('# ${novel.title}');
    buffer.writeln();
    
    if (novel.author != null) {
      buffer.writeln('**作者：** ${novel.author!.username}');
    }
    
    buffer.writeln('**创建时间：** ${DateFormat('yyyy-MM-dd HH:mm').format(novel.createdAt)}');
    buffer.writeln('**最后更新：** ${DateFormat('yyyy-MM-dd HH:mm').format(novel.updatedAt)}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 内容
    for (final act in novel.acts) {
      // 幕标题 (二级标题)
      buffer.writeln('## ${act.title}');
      buffer.writeln();
      
      for (final chapter in act.chapters) {
        // 章节标题 (三级标题)
        buffer.writeln('### ${chapter.title}');
        buffer.writeln();
        
        for (final scene in chapter.scenes) {
          // 场景内容
          if (scene.content.isNotEmpty) {
            buffer.writeln(scene.content);
            buffer.writeln();
          }
          
          // 如果场景有摘要，作为引用添加
          if (scene.summary != null && scene.summary!.content.isNotEmpty) {
            buffer.writeln('> **场景摘要：** ${scene.summary!.content}');
            buffer.writeln();
          }
        }
      }
    }

    return buffer.toString();
  }

  /// 将小说导出为JSON格式
  String _exportToJson(Novel novel) {
    final jsonData = {
      'exportInfo': {
        'exportedAt': DateTime.now().toIso8601String(),
        'exportVersion': '1.0.0',
        'appVersion': '0.1.0+1',
      },
      'novel': novel.toJson(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(jsonData);
  }

  /// 生成文件名
  String _generateFileName(Novel novel, NovelExportFormat format) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safeTitle = novel.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return '${safeTitle}_$timestamp.${format.name}';
  }

  /// 导出小说到本地文件
  Future<NovelExportResult> exportNovelToFile(
    String novelId, {
    NovelExportFormat format = NovelExportFormat.txt,
    String? customFileName,
  }) async {
    try {
      AppLogger.i('NovelFileService', '开始导出小说: $novelId, 格式: ${format.name}');
      
      // 1. 获取完整小说内容
      final novel = await _fetchCompleteNovel(novelId);
      
      // 2. 根据格式生成内容
      String content;
      switch (format) {
        case NovelExportFormat.txt:
          content = _exportToTxt(novel);
          break;
        case NovelExportFormat.markdown:
          content = _exportToMarkdown(novel);
          break;
        case NovelExportFormat.json:
          content = _exportToJson(novel);
          break;
      }
      
      // 3. 生成文件名
      final fileName = customFileName ?? _generateFileName(novel, format);
      
      // 4. 获取存储目录
      final directory = await _getNovelStorageDirectory();
      
      // 5. 写入文件
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);
      
      // 6. 获取文件大小
      final fileStat = await file.stat();
      
      final result = NovelExportResult(
        filePath: file.path,
        fileName: fileName,
        fileSizeBytes: fileStat.size,
        format: format,
        exportedAt: DateTime.now(),
      );
      
      AppLogger.i('NovelFileService', '小说导出成功: ${result.fileName}, 大小: ${result.fileSizeBytes} bytes');
      return result;
      
    } catch (e) {
      AppLogger.e('NovelFileService', '导出小说失败: $novelId', e);
      rethrow;
    }
  }

  /// 批量导出小说（多种格式）
  Future<List<NovelExportResult>> exportNovelMultipleFormats(
    String novelId, {
    List<NovelExportFormat> formats = const [
      NovelExportFormat.txt,
      NovelExportFormat.markdown,
      NovelExportFormat.json,
    ],
  }) async {
    final results = <NovelExportResult>[];
    
    for (final format in formats) {
      try {
        final result = await exportNovelToFile(novelId, format: format);
        results.add(result);
      } catch (e) {
        AppLogger.e('NovelFileService', '导出格式 ${format.name} 失败', e);
        // 继续导出其他格式
      }
    }
    
    return results;
  }

  /// 分享导出的文件
  Future<void> shareExportedFile(NovelExportResult exportResult) async {
    try {
      final file = File(exportResult.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(exportResult.filePath)],
          text: '分享小说文件：${exportResult.fileName}',
        );
        AppLogger.i('NovelFileService', '分享文件成功: ${exportResult.fileName}');
      } else {
        throw Exception('文件不存在：${exportResult.filePath}');
      }
    } catch (e) {
      AppLogger.e('NovelFileService', '分享文件失败', e);
      rethrow;
    }
  }

  /// 获取已导出文件列表
  Future<List<NovelExportResult>> getExportedFiles() async {
    try {
      final directory = await _getNovelStorageDirectory();
      
      if (!await directory.exists()) {
        return [];
      }
      
      final files = await directory.list().where((entity) => entity is File).cast<File>().toList();
      final results = <NovelExportResult>[];
      
      for (final file in files) {
        try {
          final fileName = file.path.split('/').last;
          final fileStat = await file.stat();
          
          // 尝试从文件名推断格式
          NovelExportFormat format = NovelExportFormat.txt;
          if (fileName.endsWith('.md')) {
            format = NovelExportFormat.markdown;
          } else if (fileName.endsWith('.json')) {
            format = NovelExportFormat.json;
          }
          
          results.add(NovelExportResult(
            filePath: file.path,
            fileName: fileName,
            fileSizeBytes: fileStat.size,
            format: format,
            exportedAt: fileStat.modified,
          ));
        } catch (e) {
          AppLogger.w('NovelFileService', '无法获取文件信息: ${file.path}', e);
        }
      }
      
      // 按修改时间倒序排列
      results.sort((a, b) => b.exportedAt.compareTo(a.exportedAt));
      return results;
      
    } catch (e) {
      AppLogger.e('NovelFileService', '获取导出文件列表失败', e);
      return [];
    }
  }

  /// 删除导出的文件
  Future<bool> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.i('NovelFileService', '删除文件成功: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('NovelFileService', '删除文件失败: $filePath', e);
      return false;
    }
  }

  /// 清理过期的导出文件（超过30天）
  Future<int> cleanupOldExports({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final directory = await _getNovelStorageDirectory();
      
      if (!await directory.exists()) {
        return 0;
      }
      
      final files = await directory.list().where((entity) => entity is File).cast<File>().toList();
      final now = DateTime.now();
      int deletedCount = 0;
      
      for (final file in files) {
        try {
          final fileStat = await file.stat();
          if (now.difference(fileStat.modified) > maxAge) {
            await file.delete();
            deletedCount++;
            AppLogger.i('NovelFileService', '清理过期文件: ${file.path}');
          }
        } catch (e) {
          AppLogger.w('NovelFileService', '清理文件时出错: ${file.path}', e);
        }
      }
      
      AppLogger.i('NovelFileService', '清理完成，删除了 $deletedCount 个过期文件');
      return deletedCount;
      
    } catch (e) {
      AppLogger.e('NovelFileService', '清理过期文件失败', e);
      return 0;
    }
  }

  /// 获取存储目录路径（用于用户查看）
  Future<String> getStorageDirectoryPath() async {
    final directory = await _getNovelStorageDirectory();
    return directory.path;
  }

  /// 检查存储空间使用情况
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final directory = await _getNovelStorageDirectory();
      
      if (!await directory.exists()) {
        return {
          'directoryPath': directory.path,
          'fileCount': 0,
          'totalSizeBytes': 0,
          'totalSizeMB': 0.0,
        };
      }
      
      final files = await directory.list().where((entity) => entity is File).cast<File>().toList();
      int totalSize = 0;
      
      for (final file in files) {
        try {
          final fileStat = await file.stat();
          totalSize += fileStat.size;
        } catch (e) {
          AppLogger.w('NovelFileService', '无法获取文件大小: ${file.path}', e);
        }
      }
      
      return {
        'directoryPath': directory.path,
        'fileCount': files.length,
        'totalSizeBytes': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
      };
      
    } catch (e) {
      AppLogger.e('NovelFileService', '获取存储信息失败', e);
      return {
        'directoryPath': 'unknown',
        'fileCount': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': 0.0,
      };
    }
  }
} 