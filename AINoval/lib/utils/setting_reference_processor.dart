import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ainoval/models/novel_setting_item.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:flutter/scheduler.dart';

/// AC自动机节点
class _ACNode {
  Map<String, _ACNode> children = {};
  _ACNode? failure;
  List<String> outputs = [];
  
  void addOutput(String settingId) {
    outputs.add(settingId);
  }
}

/// Aho-Corasick 自动机
class _AhoCorasick {
  final _ACNode root = _ACNode();
  
  void build(Map<String, String> patterns) {
    // 构建 Trie
    patterns.forEach((name, settingId) {
      _ACNode current = root;
      for (int i = 0; i < name.length; i++) {
        final char = name[i];
        current.children[char] ??= _ACNode();
        current = current.children[char]!;
      }
      current.addOutput(settingId);
    });
    
    // 构建失败函数
    _buildFailure();
  }
  
  void _buildFailure() {
    final queue = <_ACNode>[];
    
    // 第一层节点的失败函数指向根节点
    root.children.values.forEach((node) {
      node.failure = root;
      queue.add(node);
    });
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      
      current.children.forEach((char, child) {
        queue.add(child);
        
        _ACNode? temp = current.failure;
        while (temp != null && !temp.children.containsKey(char)) {
          temp = temp.failure;
        }
        
        child.failure = temp?.children[char] ?? root;
        child.outputs.addAll(child.failure!.outputs);
      });
    }
  }
  
  List<SettingMatch> search(String text, Map<String, String> idToName) {
    final matches = <SettingMatch>[];
    _ACNode current = root;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      while (current != root && !current.children.containsKey(char)) {
        current = current.failure!;
      }
      
      if (current.children.containsKey(char)) {
        current = current.children[char]!;
      }
      
      for (final settingId in current.outputs) {
        final name = idToName[settingId]!;
        final start = i - name.length + 1;
        matches.add(SettingMatch(
          text: name,
          start: start,
          end: i + 1,
          settingId: settingId,
          settingName: name,
        ));
      }
    }
    
    return matches;
  }
}

/// 设定引用处理器缓存
class _ProcessorCache {
  int textHash = 0;
  String lastProcessedText = '';
  List<SettingMatch> lastMatches = [];
  int settingVersion = 0;
  _AhoCorasick? automaton;
  
  void updateHash(String text) {
    textHash = text.hashCode;
    lastProcessedText = text;
  }
}

/// 设定引用匹配结果
class SettingMatch {
  final String text;        // 匹配的文本
  final int start;          // 开始位置
  final int end;            // 结束位置
  final String settingId;   // 设定ID
  final String settingName; // 设定名称

  SettingMatch({
    required this.text,
    required this.start,
    required this.end,
    required this.settingId,
    required this.settingName,
  });

  @override
  String toString() => 'SettingMatch(text: "$text", pos: $start-$end, id: $settingId)';
}

/// 设定引用处理器 - Flutter Quill原生实现
/// 使用Flutter Quill的Attribute系统来实现设定引用高亮
class SettingReferenceProcessor {
  static const String _tag = 'SettingReferenceProcessor';
  
  /// 设定引用的自定义属性名（存储设定ID）
  static const String settingReferenceAttr = 'setting-reference';
  
  /// 设定引用样式属性名（用于CSS选择器识别）
  static const String settingStyleAttr = 'setting-style';
  
  // 🚀 三层架构：全局缓存映射
  static final Map<String, _ProcessorCache> _cacheMap = {};
  static int _globalSettingVersion = 0;
  
  /// 更新全局设定版本（当设定发生变化时调用）
  static void updateSettingVersion() {
    _globalSettingVersion++;
    // 清空所有缓存的自动机，强制重建
    _cacheMap.values.forEach((cache) {
      cache.automaton = null;
      cache.settingVersion = 0;
    });
  }
  
  /// 【第二层：扫描层】使用AC自动机进行高效匹配
  static List<SettingMatch> _scanForMatches(
    String sceneId,
    String text,
    List<NovelSettingItem> settings,
  ) {
    final cache = _cacheMap[sceneId]!;
    
    // 检查是否需要重建自动机
    if (cache.automaton == null || cache.settingVersion != _globalSettingVersion) {
      final patterns = <String, String>{};
      final idToName = <String, String>{};
      
      for (final setting in settings) {
        final name = setting.name;
        final id = setting.id;
        if (name != null && name.trim().isNotEmpty && id != null && id.isNotEmpty) {
          patterns[name] = id;
          idToName[id] = name;
        }
      }
      
      cache.automaton = _AhoCorasick();
      cache.automaton!.build(patterns);
      cache.settingVersion = _globalSettingVersion;
      
      AppLogger.d(_tag, '重建AC自动机，设定数量: ${patterns.length}');
    }
    
    // 使用自动机搜索
    final idToName = <String, String>{};
    for (final setting in settings) {
      final name = setting.name;
      final id = setting.id;
      if (name != null && id != null) {
        idToName[id] = name;
      }
    }
    
    return cache.automaton!.search(text, idToName);
  }
  
  /// 【第三层：修改层】异步应用样式
  static Future<void> _applyStylesAsync(
    QuillController controller,
    List<SettingMatch> matches,
  ) async {
    if (matches.isEmpty) return;
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        final originalSelection = controller.selection;

        for (final match in matches.reversed) {
          final refAttr = Attribute(settingReferenceAttr, AttributeScope.inline, match.settingId);
          final styleAttr = Attribute(settingStyleAttr, AttributeScope.inline, 'reference');

          controller.formatText(match.start, match.text.length, refAttr);
          controller.formatText(match.start, match.text.length, styleAttr);
        }

        controller.updateSelection(originalSelection, ChangeSource.silent);
      } catch (e) {
        AppLogger.e(_tag, '样式应用失败', e);
      }
    });
  }

  /// 悬停状态管理
  static String? _currentHoveredSettingId;
  static QuillController? _currentHoveringController;
  static int? _hoveredTextStart;
  static int? _hoveredTextLength;

  /// 🎯 主要方法：处理文档中的设定引用
  /// 使用Flutter Quill原生Attribute系统添加样式
  static void processSettingReferences({
    required Document document,
    required List<NovelSettingItem> settingItems,
    required QuillController controller,
  }) {
    try {
      // 🚀 第一层：检测层 - 快速检测是否需要处理
      final currentText = document.toPlainText();
      final textHash = currentText.hashCode;
      
      // 使用文档hashCode作为临时sceneId
      final sceneId = 'doc_${document.hashCode}';
      final cache = _cacheMap.putIfAbsent(sceneId, () => _ProcessorCache());
      
      if (textHash == cache.textHash) {
        // 文本无变化，跳过处理
        return;
      }
      
      AppLogger.i(_tag, '🎯 开始三层架构设定引用处理');
      
      if (settingItems.isEmpty) {
        //AppLogger.d(_tag, '无设定条目，跳过处理');
        return;
      }

      // 🚀 第二层：扫描层 - 使用AC自动机进行高效匹配
      final matches = _scanForMatches(sceneId, currentText, settingItems);
      
      // 更新缓存
      cache.updateHash(currentText);
      cache.lastMatches = matches;
      
      AppLogger.i(_tag, '🎉 找到 ${matches.length} 个设定引用匹配');

      if (matches.isEmpty) {
        //AppLogger.d(_tag, '未找到设定引用，跳过样式应用');
        return;
      }

      // 🚀 第三层：修改层 - 异步应用样式
      _applyStylesAsync(controller, matches);
      
      AppLogger.i(_tag, '✅ 设定引用处理完成');
      
    } catch (e) {
      AppLogger.e(_tag, '设定引用处理失败', e);
    }
  }

  /// 🔍 查找设定匹配项
  static List<SettingMatch> findSettingMatches(String text, List<NovelSettingItem> settingItems) {
    final matches = <SettingMatch>[];
    
    try {
      //AppLogger.d(_tag, '🔍 开始查找设定匹配，设定数量: ${settingItems.length}');
      
      if (text.isEmpty || settingItems.isEmpty) {
        return matches;
      }

      // 创建设定名称到ID的映射
      final settingNameToId = <String, String>{};
      for (final item in settingItems) {
        final name = item.name;
        final id = item.id;
        if (name != null && name.isNotEmpty && id != null && id.isNotEmpty) {
          settingNameToId[name] = id;
        }
      }

      // 按长度排序设定名称，避免短名称覆盖长名称
      final sortedNames = settingNameToId.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
      
      //AppLogger.d(_tag, '📚 设定名称列表: ${sortedNames.join(', ')}');

      // 🚀 调试：特别检查"小胖"是否在文本中
      final xiaoPangInText = text.contains('小胖');
      //AppLogger.d(_tag, '🔍 特别检查"小胖"是否在文本中: $xiaoPangInText');
      if (xiaoPangInText) {
        final positions = <int>[];
        int searchStart = 0;
        while (true) {
          final index = text.indexOf('小胖', searchStart);
          if (index == -1) break;
          positions.add(index);
          searchStart = index + 1;
        }
        //AppLogger.d(_tag, '🔍 "小胖"在文本中的位置: $positions');
      }

      // 查找所有匹配
      for (final settingName in sortedNames) {
        final settingId = settingNameToId[settingName]!; // 使用!因为我们确定key存在
        
        // 🚀 调试：特别关注"小胖"的处理过程
        if (settingName == '小胖') {
          //AppLogger.d(_tag, '🎯 开始处理设定"小胖", ID: $settingId');
        }
        
        int searchStart = 0;
        while (true) {
          final index = text.indexOf(settingName, searchStart);
          if (index == -1) break;
          
          // 🚀 调试：记录找到的位置
          if (settingName == '小胖') {
            //AppLogger.d(_tag, '🎯 找到"小胖"在位置: $index');
          }
          
          // 检查是否是完整的词（可选：避免部分匹配）
          final isWordBoundary = _isWordBoundary(text, index, settingName.length);
          
          // 🚀 调试：记录边界检查结果
          if (settingName == '小胖') {
            //AppLogger.d(_tag, '🎯 "小胖"边界检查结果: $isWordBoundary');
          }
          
          if (isWordBoundary) {
            final match = SettingMatch(
              text: settingName,
              start: index,
              end: index + settingName.length,
              settingId: settingId,
              settingName: settingName,
            );
            
            // 检查是否与已有匹配重叠
            if (!_hasOverlap(matches, match)) {
              matches.add(match);
              ////AppLogger.v(_tag, '✅ 添加匹配: $match');
            } else {
              // 🚀 调试：记录重叠情况
              if (settingName == '小胖') {
                //AppLogger.d(_tag, '🎯 "小胖"匹配被跳过（与已有匹配重叠）');
              }
            }
          }
          
          searchStart = index + 1;
        }
      }

      // 按位置排序
      matches.sort((a, b) => a.start.compareTo(b.start));
      
      AppLogger.i(_tag, '🎉 总共找到 ${matches.length} 个有效匹配');
      for (final match in matches) {
        ////AppLogger.v(_tag, '   📍 ${match.settingName} (${match.start}-${match.end})');
      }

    } catch (e) {
      AppLogger.e(_tag, '查找设定匹配失败', e);
    }

    return matches;
  }

  /// 🎨 应用Flutter Quill样式
  static void _applyFlutterQuillStyles(QuillController controller, List<SettingMatch> matches) {
    if (matches.isEmpty) return;

    final settingRefAttribute = Attribute.clone(
      Attribute.link,
      'setting_reference',
    );
    final settingStyleAttribute = Attribute.clone(
      Attribute.color,
      const Color(0xFF0066CC).value,
    );

    try {
      // 🚀 批量应用样式，避免多次触发 document change
      final originalSelection = controller.selection;
      
      // 逆序处理，避免位置偏移
      for (final match in matches.reversed) {
        controller.formatText(
          match.start,
          match.text.length,
          settingRefAttribute,
        );
        controller.formatText(
          match.start,
          match.text.length,
          settingStyleAttribute,
        );
      }
      
      // 恢复原始选择
      controller.updateSelection(originalSelection, ChangeSource.silent);
      
    } catch (e) {
      AppLogger.e(_tag, 'Flutter Quill样式应用失败', e);
    }
  }

  /// 检查是否是完整的词边界
  static bool _isWordBoundary(String text, int start, int length) {
    // 🚀 修复：改进中文字符的词边界检查
    final before = start > 0 ? text[start - 1] : ' ';
    final after = start + length < text.length ? text[start + length] : ' ';
    
    final beforeIsWord = _isWordChar(before);
    final afterIsWord = _isWordChar(after);
    
    // 🚀 调试：添加详细的边界检查日志
    ////AppLogger.v(_tag, '🔍 词边界检查: "${text.substring(start, start + length)}" | 前:"$before"(${beforeIsWord ? "词" : "非词"}) 后:"$after"(${afterIsWord ? "词" : "非词"})');
    
    // 🚀 修复：对于中文，采用更宽松的边界检查
    // 如果前后都不是字母数字，则认为是完整的词
    return !beforeIsWord && !afterIsWord;
  }

  /// 检查字符是否是单词字符
  static bool _isWordChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    
    // 🚀 修复：简化单词字符判断，对中文更友好
    // 只有字母和数字才算单词字符，中文字符不算
    return (code >= 65 && code <= 90) ||    // A-Z
           (code >= 97 && code <= 122) ||   // a-z
           (code >= 48 && code <= 57);      // 0-9
    // 移除中文字符判断，这样中文前后的字符不会影响匹配
  }

  /// 检查匹配是否重叠
  static bool _hasOverlap(List<SettingMatch> existingMatches, SettingMatch newMatch) {
    for (final existing in existingMatches) {
      if ((newMatch.start < existing.end && newMatch.end > existing.start)) {
        return true;
      }
    }
    return false;
  }

  /// 🛡️ 清除格式传播，防止设定引用样式影响后续输入
  static void _clearFormattingPropagation(QuillController controller) {
    try {
      //AppLogger.d(_tag, '🛡️ 清除格式传播');
      
      // 获取当前选择
      final selection = controller.selection;
      
      // 🎯 简化格式传播清除逻辑
      // 不直接操作文档内容，而是通过设置光标样式状态来防止传播
      if (selection.isCollapsed) {
        final currentOffset = selection.baseOffset;
        
        // 🛡️ 只在光标位置插入一个零宽字符来重置格式状态
        // 这样不会影响已经应用的设定引用样式
        try {
          // 保存当前选择
          final originalSelection = controller.selection;
          
          // 临时在光标位置插入零宽空格，然后立即删除
          // 这可以重置光标位置的格式继承状态
          final zeroWidthSpace = '\u200B'; // 零宽空格
          controller.replaceText(currentOffset, 0, zeroWidthSpace, TextSelection.collapsed(offset: currentOffset + 1));
          controller.replaceText(currentOffset, 1, '', TextSelection.collapsed(offset: currentOffset));
          
          // 恢复原始选择
          controller.updateSelection(originalSelection, ChangeSource.silent);
          
          ////AppLogger.v(_tag, '✅ 已重置光标位置的格式继承状态');
          
        } catch (e) {
          AppLogger.w(_tag, '重置格式继承状态失败，使用备用方案', e);
          
          // 备用方案：简单地清除当前选择的格式状态
          // 注意：这里不使用formatText，避免影响已有的设定引用样式
          ////AppLogger.v(_tag, '✅ 使用备用格式传播清除方案');
        }
      }
      
    } catch (e) {
      AppLogger.w(_tag, '清除格式传播失败', e);
    }
  }

  /// 🎯 移除设定引用样式
  static void removeSettingReferenceStyles(QuillController controller) {
    try {
      AppLogger.i(_tag, '🗑️ 移除所有设定引用样式');
      
      final document = controller.document;
      final text = document.toPlainText();
      
      if (text.isEmpty) return;
      
      // 移除所有设定引用相关的属性
      final removeAttributes = [
        Attribute(settingReferenceAttr, AttributeScope.inline, null),
        Attribute(settingStyleAttr, AttributeScope.inline, null),
      ];
      
      for (final attr in removeAttributes) {
        controller.formatText(0, text.length, attr);
      }
      
      AppLogger.i(_tag, '✅ 设定引用样式移除完成');
      
    } catch (e) {
      AppLogger.e(_tag, '移除设定引用样式失败', e);
    }
  }

  /// 🔄 刷新设定引用样式
  static void refreshSettingReferences({
    required QuillController controller,
    required List<NovelSettingItem> settingItems,
  }) {
    try {
      AppLogger.i(_tag, '🔄 刷新设定引用样式');
      
      // 1. 先移除现有样式
      removeSettingReferenceStyles(controller);
      
      // 2. 重新应用样式
      processSettingReferences(
        document: controller.document,
        settingItems: settingItems,
        controller: controller,
      );
      
      AppLogger.i(_tag, '✅ 设定引用样式刷新完成');
      
    } catch (e) {
      AppLogger.e(_tag, '刷新设定引用样式失败', e);
    }
  }

  /// 🛡️ 清除光标位置的设定引用格式传播（公共方法）
  /// 应在用户输入时调用，防止设定引用样式影响新输入的文本
  static void clearFormattingPropagationAtCursor(QuillController controller) {
    _clearFormattingPropagation(controller);
  }

  /// 🧹 用于保存时的设定引用样式过滤（保留原功能）
  static String filterSettingReferenceStylesForSave(String deltaJson, {String? caller}) {
    return filterSettingReferenceStyles(deltaJson, caller: caller ?? 'filterSettingReferenceStylesForSave');
  }

  /// 🔄 用于编辑时的内容处理（不过滤设定引用样式）
  /// 在编辑过程中，我们要保留设定引用样式以便显示
  static String processContentForEditing(String deltaJson) {
    // 编辑时不过滤设定引用样式，直接返回原内容
    return deltaJson;
  }

  /// 清理场景缓存
  static void clearSceneCache(String sceneId) {
    _cacheMap.remove(sceneId);
  }
  
  /// 清理所有缓存
  static void clearAllCache() {
    _cacheMap.clear();
  }

  /// 🧹 过滤设定引用相关的自定义样式，保留其他样式
  /// 用于保存时清理临时的设定引用样式，但保留用户的格式化样式
  static String filterSettingReferenceStyles(String deltaJson, {String? caller}) {
    try {
      // 🎯 优化：减少频繁日志输出，仅在调试模式或特定调用者时输出
      if (caller == null || caller == 'debug') {
        //AppLogger.d(_tag, '🧹 开始过滤设定引用样式${caller != null ? ' - 调用者: $caller' : ''}');
      }
      
      // 解析Delta JSON
      final dynamic deltaData = jsonDecode(deltaJson);
      List<dynamic> ops;
      
      if (deltaData is List) {
        // 格式1: 直接是ops数组 [{"insert": "text"}, ...]
        ////AppLogger.v(_tag, '📋 检测到直接ops数组格式');
        ops = deltaData;
      } else if (deltaData is Map<String, dynamic>) {
        // 格式2: 标准Delta格式 {"ops": [{"insert": "text"}, ...]}
        ////AppLogger.v(_tag, '📋 检测到标准Delta格式');
        final dynamic opsData = deltaData['ops'];
        
        if (opsData is! List) {
          AppLogger.w(_tag, '❌ ops数据不是预期的List格式');
          return deltaJson;
        }
        ops = opsData;
      } else {
        AppLogger.w(_tag, '❌ Delta数据格式不支持: ${deltaData.runtimeType}');
        return deltaJson;
      }
      
      // 过滤操作列表
      final List<dynamic> filteredOps = [];
      
      for (int i = 0; i < ops.length; i++) {
        final dynamic op = ops[i];
        
        // 只处理Map类型的操作
        if (op is Map<String, dynamic>) {
          // 创建新的操作副本
          final Map<String, dynamic> newOp = <String, dynamic>{};
          
          // 复制所有字段
          op.forEach((key, value) {
            newOp[key] = value;
          });
          
          // 检查是否有attributes字段
          if (newOp.containsKey('attributes') && newOp['attributes'] is Map) {
            final dynamic attributesData = newOp['attributes'];
            
            if (attributesData is Map<String, dynamic>) {
              // 创建属性副本
              final Map<String, dynamic> attributes = <String, dynamic>{};
              attributesData.forEach((key, value) {
                attributes[key] = value;
              });
              
              // 移除设定引用相关的属性
              bool hasRemovedAttrs = false;
              if (attributes.containsKey(settingReferenceAttr)) {
                attributes.remove(settingReferenceAttr);
                hasRemovedAttrs = true;
              }
              if (attributes.containsKey(settingStyleAttr)) {
                attributes.remove(settingStyleAttr);
                hasRemovedAttrs = true;
              }
              
              // // 如果移除了属性，记录日志
              // if (hasRemovedAttrs) {
              //   ////AppLogger.v(_tag, '🗑️ 已移除设定引用属性: op[$i]');
              // }
              
              // 如果还有其他属性，保留attributes；否则移除整个attributes字段
              if (attributes.isNotEmpty) {
                newOp['attributes'] = attributes;
              } else {
                newOp.remove('attributes');
              }
            }
          }
          
          filteredOps.add(newOp);
        } else {
          // 非Map类型的操作直接保留（通常不应该发生）
          ////AppLogger.v(_tag, '⚠️ 跳过非Map类型的操作: ${op.runtimeType}');
          filteredOps.add(op);
        }
      }
      
      // 重新构造Delta，保持原有格式
      final dynamic filteredResult;
      if (deltaData is List) {
        // 如果原始数据是数组格式，返回数组
        filteredResult = filteredOps;
      } else {
        // 如果原始数据是标准Delta格式，返回包含ops的对象
        filteredResult = {
          'ops': filteredOps,
        };
      }
      
      final String filteredJson = jsonEncode(filteredResult);
      
      // 🎯 优化：减少频繁日志输出
      if (caller == null || caller == 'debug') {
        //AppLogger.d(_tag, '✅ 设定引用样式过滤完成${caller != null ? ' - 调用者: $caller' : ''}');
        ////AppLogger.v(_tag, '   原始长度: ${deltaJson.length}, 过滤后长度: ${filteredJson.length}');
      }
      
      return filteredJson;
      
    } catch (e, stackTrace) {
      AppLogger.w(_tag, '过滤设定引用样式失败，返回原始内容', e);
      ////AppLogger.v(_tag, '错误详情', e, stackTrace);
      return deltaJson; // 出错时返回原始内容
    }
  }

  /// 🎯 处理设定引用悬停开始 - 使用精确位置（新版本，推荐使用）
  static void handleSettingReferenceHoverStartWithPosition({
    required QuillController controller,
    required String settingId,
    required int textStart,
    required int textLength,
  }) {
    try {
      //AppLogger.d(_tag, '🖱️ 开始处理设定引用悬停（使用精确位置）: $settingId (位置: $textStart-${textStart + textLength})');
      
      // 如果当前已有悬停状态，先清除
      if (_currentHoveredSettingId != null) {
        handleSettingReferenceHoverEnd();
      }
      
      // 直接使用传递的位置信息，不再计算
      _currentHoveredSettingId = settingId;
      _currentHoveringController = controller;
      _hoveredTextStart = textStart;
      _hoveredTextLength = textLength;
      
      // 添加黄色背景属性（使用Flutter Quill标准background属性）
      final hoverBackgroundAttribute = Attribute(
        'background',
        AttributeScope.inline,
        '#FFF3CD', // 浅黄色背景
      );
      
      // 保存当前选择状态
      final originalSelection = controller.selection;
      
      // 应用悬停背景
      controller.formatText(
        _hoveredTextStart!,
        _hoveredTextLength!,
        hoverBackgroundAttribute,
      );
      
      // 恢复选择状态
      controller.updateSelection(originalSelection, ChangeSource.silent);
      
      ////AppLogger.v(_tag, '✅ 已添加悬停背景（精确位置）: $settingId (${_hoveredTextStart}-${_hoveredTextStart! + _hoveredTextLength!})');
      
    } catch (e) {
      AppLogger.e(_tag, '处理设定引用悬停开始失败（精确位置）: $settingId', e);
    }
  }

  /// 🎯 处理设定引用悬停结束 - 移除黄色背景
  static void handleSettingReferenceHoverEnd() {
    try {
      if (_currentHoveredSettingId == null || 
          _currentHoveringController == null ||
          _hoveredTextStart == null ||
          _hoveredTextLength == null) {
        return;
      }
      
      //AppLogger.d(_tag, '🖱️ 结束处理设定引用悬停: $_currentHoveredSettingId');
      
      // 移除悬停背景属性（使用Flutter Quill标准background属性）
      final removeHoverBackgroundAttribute = Attribute(
        'background',
        AttributeScope.inline,
        null, // null值表示移除属性
      );
      
      // 保存当前选择状态
      final originalSelection = _currentHoveringController!.selection;
      
      // 移除悬停背景
      _currentHoveringController!.formatText(
        _hoveredTextStart!,
        _hoveredTextLength!,
        removeHoverBackgroundAttribute,
      );
      
      // 恢复选择状态
      _currentHoveringController!.updateSelection(originalSelection, ChangeSource.silent);
      
      ////AppLogger.v(_tag, '✅ 已移除悬停背景: $_currentHoveredSettingId');
      
      // 清除悬停状态
      _currentHoveredSettingId = null;
      _currentHoveringController = null;
      _hoveredTextStart = null;
      _hoveredTextLength = null;
      
    } catch (e) {
      AppLogger.e(_tag, '处理设定引用悬停结束失败', e);
    }
  }

} 