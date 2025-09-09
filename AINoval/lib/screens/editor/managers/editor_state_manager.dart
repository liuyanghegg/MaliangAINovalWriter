import 'package:ainoval/blocs/editor/editor_bloc.dart' as editor_bloc;
import 'package:ainoval/models/novel_structure.dart' as novel_models;
import 'package:ainoval/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 编辑器状态管理器
/// 负责管理编辑器的状态，如字数统计、控制器检查等
class EditorStateManager {
  EditorStateManager();

  // 控制器检查节流相关变量
  DateTime? _lastControllerCheckTime;
  static const Duration _controllerCheckInterval = Duration(milliseconds: 500);
  static const Duration _controllerLongCheckInterval = Duration(seconds: 5);
  editor_bloc.EditorLoaded? _lastEditorState;

  // 字数统计缓存
  int _cachedWordCount = 0;
  String? _wordCountCacheKey;
  final Map<String, int> _memoryWordCountCache = {};
  
  // 🔧 新增：模型验证状态跟踪，防止模型操作影响编辑器状态
  bool _isModelOperationInProgress = false;
  DateTime? _lastModelOperationTime;
  static const Duration _modelOperationCooldown = Duration(seconds: 5);

  // 🔧 新增：设置模型操作状态
  void setModelOperationInProgress(bool inProgress) {
    _isModelOperationInProgress = inProgress;
    if (inProgress) {
      _lastModelOperationTime = DateTime.now();
      AppLogger.i('EditorStateManager', '模型操作开始，暂停控制器检查');
    } else {
      AppLogger.i('EditorStateManager', '模型操作结束');
    }
  }
  
  // 🔧 新增：检查是否在模型操作冷却期
  bool get _isInModelOperationCooldown {
    if (_lastModelOperationTime == null) return false;
    final now = DateTime.now();
    final inCooldown = now.difference(_lastModelOperationTime!) < _modelOperationCooldown;
    if (inCooldown) {
      AppLogger.d('EditorStateManager', '模型操作冷却期中，跳过控制器检查');
    }
    return inCooldown;
  }

  // 清除内存缓存
  void clearMemoryCache() {
    _memoryWordCountCache.clear();
  }

  // 计算总字数
  int calculateTotalWordCount(novel_models.Novel novel) {
    // 生成缓存键：使用更新时间和场景总数作为缓存键
    final totalSceneCount = novel.acts.fold(0, (sum, act) => 
        sum + act.chapters.fold(0, (sum, chapter) => 
            sum + chapter.scenes.length));
    
    final updatedAtMs = novel.updatedAt.millisecondsSinceEpoch ?? 0;
    final cacheKey = '${novel.id}_${updatedAtMs}_$totalSceneCount';
    
    // 首先检查内存缓存，这是最快的检查方式
    if (_memoryWordCountCache.containsKey(cacheKey)) {
      // 完全跳过日志记录以提高性能
      return _memoryWordCountCache[cacheKey]!;
    }
    
    // 如果持久化缓存有效，直接返回缓存的字数
    if (cacheKey == _wordCountCacheKey && _cachedWordCount > 0) {
      // 同时更新内存缓存
      _memoryWordCountCache[cacheKey] = _cachedWordCount;
      return _cachedWordCount;
    }
    
      // 检查是否在滚动过程中 - 如果在滚动，使用旧缓存或返回0而不是计算
      final now = DateTime.now();
      if (_lastScrollHandleTime != null && 
          now.difference(_lastScrollHandleTime!) < const Duration(seconds: 2)) {
        // 在滚动过程中，如果有缓存直接用，没有就返回0避免计算
        if (_cachedWordCount > 0) {
          AppLogger.d('EditorStateManager', '滚动中使用缓存字数: $_cachedWordCount');
          // 同时更新内存缓存
          _memoryWordCountCache[cacheKey] = _cachedWordCount;
          return _cachedWordCount;
        } else {
          AppLogger.d('EditorStateManager', '滚动中跳过字数计算');
          return 0; // 返回0避免计算
        }
    }
    
    // 正常情况下，记录字数计算原因
    AppLogger.i('EditorStateManager', '字数统计缓存无效，重新计算。新缓存键: $cacheKey，旧缓存键: ${_wordCountCacheKey ?? "无"}');
  
    // 计算总字数（不再重复计算每个场景的字数）
    int totalWordCount = 0;
    for (final act in novel.acts) {
      for (final chapter in act.chapters) {
        for (final scene in chapter.scenes) {
          // 直接使用存储的字数，不重新计算
          totalWordCount += scene.wordCount;
        }
      }
    }

    // 更新缓存，并减少日志输出
    _wordCountCacheKey = cacheKey;
    _cachedWordCount = totalWordCount;
    
    // 同时更新内存缓存
    _memoryWordCountCache[cacheKey] = totalWordCount;
    
    AppLogger.i('EditorStateManager', '小说总字数计算结果: $totalWordCount (Acts: ${novel.acts.length}, 更新缓存键: $cacheKey)');
    return totalWordCount;
  }

  // 滚动处理节流
  DateTime? _lastScrollHandleTime;

  // 检查是否应该重建Quill控制器
  bool shouldCheckControllers(editor_bloc.EditorLoaded state, {bool isLayoutOnlyChange = false}) {
    if (_isModelOperationInProgress || _isInModelOperationCooldown) {
      return false;
    }
    
    // 如果是纯布局变化，跳过控制器检查
    if (isLayoutOnlyChange) {
      if (kDebugMode) {
        AppLogger.d('EditorStateManager', '跳过控制器检查 - 原因: 纯布局变化');
      }
      return false;
    }
    
    if (state.lastUpdateSilent) {
      return false;
    }
    
    // 如果状态对象引用变化，表示小说数据结构可能发生变化，需要检查
    final bool stateChanged = _lastEditorState != state;
    final now = DateTime.now();

    // 检查是否刚完成加载且内容有变化 (最重要的条件)
    bool justFinishedLoadingWithChanges = false;
    bool contentChanged = false; // Calculate contentChanged regardless of other checks

    if (stateChanged && _lastEditorState != null) {
      // 检查小说结构是否有实质变化，主要比较acts和scenes的数量
      final oldNovel = _lastEditorState!.novel;
      final newNovel = state.novel;

      // 🔧 修复：更严格的内容变化检查，避免将非内容变化误认为内容变化
      // 只有在小说结构本身发生变化时才认为是内容变化
      
      // 首先检查小说基本信息是否变化（排除时间戳）
      if (oldNovel.id != newNovel.id || 
          oldNovel.title != newNovel.title) {
        contentChanged = true;
        AppLogger.i('EditorStateManager', '检测到小说基本信息变化');
      }
      
      // 检查act数量是否变化
      else if (oldNovel.acts.length != newNovel.acts.length) {
        contentChanged = true;
        AppLogger.i('EditorStateManager', '检测到Act数量变化: ${oldNovel.acts.length} -> ${newNovel.acts.length}');
      } 
      else {
        // 检查章节和场景数量是否变化
        bool structureChanged = false;
        
        for (int i = 0; i < oldNovel.acts.length && i < newNovel.acts.length; i++) {
          final oldAct = oldNovel.acts[i];
          final newAct = newNovel.acts[i];
          
          // 检查Act基本信息
          if (oldAct.id != newAct.id || oldAct.title != newAct.title) {
            structureChanged = true;
            AppLogger.i('EditorStateManager', '检测到Act[$i]基本信息变化');
            break;
          }
          
          // 检查章节数量
          if (oldAct.chapters.length != newAct.chapters.length) {
            structureChanged = true;
            AppLogger.i('EditorStateManager', '检测到Act[$i]章节数量变化: ${oldAct.chapters.length} -> ${newAct.chapters.length}');
            break;
          }
          
          // 检查每个章节的场景数量
          for (int j = 0; j < oldAct.chapters.length && j < newAct.chapters.length; j++) {
            final oldChapter = oldAct.chapters[j];
            final newChapter = newAct.chapters[j];
            
            // 检查Chapter基本信息
            if (oldChapter.id != newChapter.id || oldChapter.title != newChapter.title) {
              structureChanged = true;
              AppLogger.i('EditorStateManager', '检测到Chapter[$i][$j]基本信息变化');
              break;
            }
            
            // 检查场景数量
            if (oldChapter.scenes.length != newChapter.scenes.length) {
              structureChanged = true;
              AppLogger.i('EditorStateManager', '检测到Chapter[$i][$j]场景数量变化: ${oldChapter.scenes.length} -> ${newChapter.scenes.length}');
              break;
            }
            
            // 检查场景ID是否变化（新增/删除场景）
            final oldSceneIds = oldChapter.scenes.map((s) => s.id).toSet();
            final newSceneIds = newChapter.scenes.map((s) => s.id).toSet();
            if (oldSceneIds.length != newSceneIds.length || 
                !oldSceneIds.containsAll(newSceneIds) || 
                !newSceneIds.containsAll(oldSceneIds)) {
              structureChanged = true;
              AppLogger.i('EditorStateManager', '检测到Chapter[$i][$j]场景ID变化');
              break;
            }
          }
          
          if (structureChanged) break;
        }
        
        contentChanged = structureChanged;
      }
      
      // *** Check if loading just finished and content actually changed ***
      if (_lastEditorState!.isLoading && !state.isLoading && contentChanged) {
        justFinishedLoadingWithChanges = true;
        // 仅在调试模式下记录日志
        if (kDebugMode) {
          AppLogger.i('EditorStateManager', '检测到加载完成且内容有变化，强制检查控制器。');
        }
      }
    }

    // *** Bypass throttle if loading just finished with changes ***
    if (justFinishedLoadingWithChanges) {
       _lastControllerCheckTime = now;
       _lastEditorState = state; // Update state reference
       // 仅在调试模式下记录日志
       if (kDebugMode) {
         AppLogger.i('EditorStateManager', '触发控制器检查 - 原因: 加载完成');
       }
       return true;
    }

    // 🔧 修复：增加节流时间到15秒，减少不必要的控制器检查
    // 极端节流：如果距离上次检查时间不足15秒，且不是刚加载完成，绝对不检查
    if (_lastControllerCheckTime != null && 
        now.difference(_lastControllerCheckTime!) < const Duration(seconds: 15)) {
      // 记录日志：禁止频繁检查 (仅在状态变化且调试模式下记录，避免日志刷屏)
      if (stateChanged && kDebugMode) {
        AppLogger.d('EditorStateManager', '节流: 禁止15秒内重复检查控制器');
      }
      // 更新状态引用，即使被节流也要更新，以便下次比较
      _lastEditorState = state;
      return false;
    }
    
    // 检查活动元素是否变化
    bool activeElementsChanged = false;
    if (stateChanged && _lastEditorState != null) {
      activeElementsChanged = 
          _lastEditorState!.activeActId != state.activeActId ||
          _lastEditorState!.activeChapterId != state.activeChapterId ||
          _lastEditorState!.activeSceneId != state.activeSceneId;
    }

    // 🔧 修复：只有在以下严格条件下才重建控制器
    // 1. 首次加载（_lastControllerCheckTime为null）
    // 2. 确实的内容结构变化（添加/删除场景或章节）
    // 3. 活动元素变化
    // 4. 长时间间隔超时 (15秒)
    final bool timeIntervalExceeded = _lastControllerCheckTime == null || 
        now.difference(_lastControllerCheckTime!) > const Duration(seconds: 15);
    
    final bool needsCheck = _lastControllerCheckTime == null || 
                           contentChanged || 
                           activeElementsChanged ||
                           timeIntervalExceeded;

    // 更新状态引用，用于下次比较
    _lastEditorState = state;
    
    // 如果需要检查，更新最后检查时间
    if (needsCheck) {
      _lastControllerCheckTime = now;
      
      // 仅在调试模式下记录日志
      if (kDebugMode) {
        String reason;
        if (contentChanged) {
          reason = '内容结构变化';
        } else if (activeElementsChanged) {
          reason = '活动元素变化';
        } else if (timeIntervalExceeded) {
           reason = '时间间隔超过(15秒)';
        } else {
          reason = '首次加载';
        }
        
        AppLogger.i('EditorStateManager', '触发控制器检查 - 原因: $reason');
      }
      return true;
    }
    
    return false;
  }

  // 内容更新通知器  
  final ValueNotifier<String> contentUpdateNotifier = ValueNotifier<String>('');
  
  // 通知内容更新
  void notifyContentUpdate(String reason) {
    AppLogger.i('EditorStateManager', '通知内容更新: $reason');
    contentUpdateNotifier.value = '${DateTime.now().millisecondsSinceEpoch}_$reason';
  }
}
