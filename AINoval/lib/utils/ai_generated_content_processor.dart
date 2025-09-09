import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:flutter_quill/quill_delta.dart';

/// AI生成内容处理器
/// 用于为AI生成的内容添加蓝色样式标识，并管理临时状态
class AIGeneratedContentProcessor {
  static const String _tag = 'AIGeneratedContentProcessor';
  
  /// AI生成内容的自定义属性名
  static const String aiGeneratedAttr = 'ai-generated';
  
  /// AI生成内容样式属性名（用于CSS选择器识别）
  static const String aiGeneratedStyleAttr = 'ai-generated-style';
  
  /// 🆕 隐藏文本的自定义属性名（用于重构时隐藏原文本）
  static const String hiddenTextAttr = 'hidden-text';
  
  /// 🆕 隐藏文本样式属性名（用于CSS选择器识别）
  static const String hiddenTextStyleAttr = 'hidden-text-style';

  /// 🎯 为指定范围的文本添加AI生成标识
  static void markAsAIGenerated({
    required QuillController controller,
    required int startOffset,
    required int length,
  }) {
    try {
      //AppLogger.d(_tag, '🎨 标记AI生成内容: 位置 $startOffset-${startOffset + length}');
      
      // 保存当前选择
      final originalSelection = controller.selection;
      
      // 创建AI生成内容的自定义属性
      const aiGeneratedAttribute = Attribute(
        aiGeneratedAttr,
        AttributeScope.inline,
        'true',
      );
      
      // 创建AI生成内容样式属性（用于CSS识别）
      const aiGeneratedStyleAttribute = Attribute(
        aiGeneratedStyleAttr,
        AttributeScope.inline,
        'generated',
      );

      // 应用AI生成标识属性
      controller.formatText(startOffset, length, aiGeneratedAttribute);
      controller.formatText(startOffset, length, aiGeneratedStyleAttribute);
      
      // 恢复选择状态
      controller.updateSelection(originalSelection, ChangeSource.silent);
      
      //AppLogger.v(_tag, '✅ AI生成内容标记完成');
      
    } catch (e) {
      AppLogger.e(_tag, '标记AI生成内容失败', e);
    }
  }

  /// 🆕 为指定范围的文本添加隐藏标识（用于重构时隐藏原文本）
  static void markAsHidden({
    required QuillController controller,
    required int startOffset,
    required int length,
  }) {
    try {
      AppLogger.i(_tag, '🫥 标记隐藏文本: 位置 $startOffset-${startOffset + length}');
      
      // 保存当前选择
      final originalSelection = controller.selection;
      
      // 创建隐藏文本的自定义属性
      const hiddenAttribute = Attribute(
        hiddenTextAttr,
        AttributeScope.inline,
        'true',
      );
      
      // 创建隐藏文本样式属性（用于CSS识别）
      const hiddenStyleAttribute = Attribute(
        hiddenTextStyleAttr,
        AttributeScope.inline,
        'hidden',
      );

      // 应用隐藏标识属性
      controller.formatText(startOffset, length, hiddenAttribute);
      controller.formatText(startOffset, length, hiddenStyleAttribute);
      
      // 恢复选择状态
      controller.updateSelection(originalSelection, ChangeSource.silent);
      
      AppLogger.v(_tag, '✅ 隐藏文本标记完成');
      
    } catch (e) {
      AppLogger.e(_tag, '标记隐藏文本失败', e);
    }
  }

  /// 🎯 移除AI生成标识，将内容转为正常文本
  static void removeAIGeneratedMarks({
    required QuillController controller,
    int? startOffset,
    int? length,
  }) {
    try {
      AppLogger.i(_tag, '🗑️ 移除AI生成标识');
      
      final document = controller.document;
      final plainText = document.toPlainText();
      
      final removeStart = startOffset ?? 0;
      final removeLength = length ?? plainText.length;
      
      if (removeLength <= 0) return;
      
      // 保存当前选择
      final originalSelection = controller.selection;
      
      // 移除AI生成相关的属性
      final removeAttributes = [
        Attribute(aiGeneratedAttr, AttributeScope.inline, null),
        Attribute(aiGeneratedStyleAttr, AttributeScope.inline, null),
      ];
      
      for (final attr in removeAttributes) {
        controller.formatText(removeStart, removeLength, attr);
      }
      
      // 恢复选择状态
      controller.updateSelection(originalSelection, ChangeSource.silent);
      
      AppLogger.i(_tag, '✅ AI生成标识移除完成');
      
    } catch (e) {
      AppLogger.e(_tag, '移除AI生成标识失败', e);
    }
  }

  /// 🆕 移除隐藏标识，显示文本（用于恢复原文本）
  static void removeHiddenMarks({
    required QuillController controller,
    int? startOffset,
    int? length,
  }) {
    try {
      AppLogger.i(_tag, '👁️ 移除隐藏标识，显示文本');
      
      final document = controller.document;
      final plainText = document.toPlainText();
      
      final removeStart = startOffset ?? 0;
      final removeLength = length ?? plainText.length;
      
      if (removeLength <= 0) return;
      
      // 保存当前选择
      final originalSelection = controller.selection;
      
      // 移除隐藏相关的属性
      final removeAttributes = [
        Attribute(hiddenTextAttr, AttributeScope.inline, null),
        Attribute(hiddenTextStyleAttr, AttributeScope.inline, null),
      ];
      
      for (final attr in removeAttributes) {
        controller.formatText(removeStart, removeLength, attr);
      }
      
      // 恢复选择状态
      controller.updateSelection(originalSelection, ChangeSource.silent);
      
      AppLogger.i(_tag, '✅ 隐藏标识移除完成，文本已显示');
      
    } catch (e) {
      AppLogger.e(_tag, '移除隐藏标识失败', e);
    }
  }

  /// 🎯 检查指定范围是否包含AI生成内容
  static bool hasAIGeneratedContent({
    required QuillController controller,
    required int startOffset,
    required int length,
  }) {
    try {
      final document = controller.document;
      
      // 遍历指定范围内的所有节点，检查是否有AI生成标识
      final delta = document.toDelta();
      int currentOffset = 0;
      
      for (final operation in delta.operations) {
        if (operation.isInsert) {
          final opLength = operation.length!;
          final opEnd = currentOffset + opLength;
          
          // 检查操作是否与指定范围重叠
          if (currentOffset < startOffset + length && opEnd > startOffset) {
            // 检查操作的属性中是否包含AI生成标识
            final attributes = operation.attributes;
            if (attributes != null && attributes.containsKey(aiGeneratedAttr)) {
              return true;
            }
          }
          
          currentOffset = opEnd;
        }
      }
      
      return false;
    } catch (e) {
      AppLogger.e(_tag, '检查AI生成内容失败', e);
      return false;
    }
  }

  /// 🎯 获取所有AI生成内容的范围
  static List<({int start, int length})> getAIGeneratedRanges({
    required QuillController controller,
  }) {
    final ranges = <({int start, int length})>[];
    
    try {
      final document = controller.document;
      final delta = document.toDelta();
      int currentOffset = 0;
      
      for (final operation in delta.operations) {
        if (operation.isInsert) {
          final opLength = operation.length!;
          
          // 检查操作的属性中是否包含AI生成标识
          final attributes = operation.attributes;
          if (attributes != null && attributes.containsKey(aiGeneratedAttr)) {
            ranges.add((start: currentOffset, length: opLength));
          }
          
          currentOffset += opLength;
        }
      }
      
      AppLogger.d(_tag, '📍 找到 ${ranges.length} 个AI生成内容范围');
      
    } catch (e) {
      AppLogger.e(_tag, '获取AI生成内容范围失败', e);
    }
    
    return ranges;
  }

  /// 🎯 获取自定义样式构建器，用于处理AI生成内容和隐藏文本的显示样式
  static TextStyle Function(Attribute) getCustomStyleBuilder() {
    return (Attribute attribute) {
      // 处理AI生成内容的样式标记
      if (attribute.key == aiGeneratedStyleAttr && 
          attribute.value == 'generated') {
        return const TextStyle(
          color: Color(0xFF2196F3), // 蓝色文字
          // 可以添加更多样式，如背景色、下划线等
        );
      }
      
      // 🆕 处理隐藏文本的样式标记
      if (attribute.key == hiddenTextStyleAttr && 
          attribute.value == 'hidden') {
        return const TextStyle(
          color: Color(0x40000000), // 25%透明度的黑色，几乎看不见
          decoration: TextDecoration.lineThrough, // 删除线
          decorationColor: Color(0x60FF0000), // 半透明红色删除线
          decorationThickness: 1.5,
          // 可选：背景色表示这是被隐藏的内容
          // backgroundColor: Color(0x10FF0000), // 淡红色背景
        );
      }
      
      return const TextStyle();
    };
  }

  /// 🎯 清除所有AI生成标识（通常在apply时调用）
  static void clearAllAIGeneratedMarks({
    required QuillController controller,
  }) {
    try {
      AppLogger.i(_tag, '🧹 清除所有AI生成标识');
      
      removeAIGeneratedMarks(
        controller: controller,
        startOffset: 0,
        length: controller.document.toPlainText().length,
      );
      
    } catch (e) {
      AppLogger.e(_tag, '清除所有AI生成标识失败', e);
    }
  }

  /// 🆕 获取所有隐藏文本的范围
  static List<({int start, int length})> getHiddenTextRanges({
    required QuillController controller,
  }) {
    final ranges = <({int start, int length})>[];
    
    try {
      final document = controller.document;
      final delta = document.toDelta();
      int currentOffset = 0;
      
      for (final operation in delta.operations) {
        if (operation.isInsert) {
          final opLength = operation.length!;
          
          // 检查操作的属性中是否包含隐藏标识
          final attributes = operation.attributes;
          if (attributes != null && attributes.containsKey(hiddenTextAttr)) {
            ranges.add((start: currentOffset, length: opLength));
          }
          
          currentOffset += opLength;
        }
      }
      
      AppLogger.d(_tag, '📍 找到 ${ranges.length} 个隐藏文本范围');
      
    } catch (e) {
      AppLogger.e(_tag, '获取隐藏文本范围失败', e);
    }
    
    return ranges;
  }

  /// 🆕 检查指定范围是否包含隐藏文本
  static bool hasHiddenText({
    required QuillController controller,
    required int startOffset,
    required int length,
  }) {
    try {
      final document = controller.document;
      
      // 遍历指定范围内的所有节点，检查是否有隐藏标识
      final delta = document.toDelta();
      int currentOffset = 0;
      
      for (final operation in delta.operations) {
        if (operation.isInsert) {
          final opLength = operation.length!;
          final opEnd = currentOffset + opLength;
          
          // 检查操作是否与指定范围重叠
          if (currentOffset < startOffset + length && opEnd > startOffset) {
            // 检查操作的属性中是否包含隐藏标识
            final attributes = operation.attributes;
            if (attributes != null && attributes.containsKey(hiddenTextAttr)) {
              return true;
            }
          }
          
          currentOffset = opEnd;
        }
      }
      
      return false;
    } catch (e) {
      AppLogger.e(_tag, '检查隐藏文本失败', e);
      return false;
    }
  }

  /// 🆕 获取过滤掉隐藏文本的纯文本内容（用于保存）
  static String getVisibleTextOnly({
    required QuillController controller,
  }) {
    try {
      final document = controller.document;
      final delta = document.toDelta();
      final visibleText = StringBuffer();
      
      for (final operation in delta.operations) {
        if (operation.isInsert) {
          final text = operation.data.toString();
          final attributes = operation.attributes;
          
          // 只包含非隐藏的文本
          if (attributes == null || !attributes.containsKey(hiddenTextAttr)) {
            visibleText.write(text);
          }
        }
      }
      
      final result = visibleText.toString();
      AppLogger.d(_tag, '📝 过滤后可见文本长度: ${result.length}');
      return result;
      
    } catch (e) {
      AppLogger.e(_tag, '获取可见文本失败', e);
      return controller.document.toPlainText(); // 回退到原始文本
    }
  }

  /// 🆕 获取过滤掉隐藏文本的Delta JSON（用于保存）
  static String getVisibleDeltaJsonOnly({
    required QuillController controller,
  }) {
    try {
      final document = controller.document;
      final originalDelta = document.toDelta();
      final visibleOperations = <Map<String, dynamic>>[];
      
      for (final operation in originalDelta.operations) {
        if (operation.isInsert) {
          final attributes = operation.attributes;
          
          // 只包含非隐藏的操作
          if (attributes == null || !attributes.containsKey(hiddenTextAttr)) {
            visibleOperations.add(operation.toJson());
          }
        } else {
          // 保留非插入操作（删除、保持等）
          visibleOperations.add(operation.toJson());
        }
      }
      
      final visibleDeltaJson = {'ops': visibleOperations};
      AppLogger.d(_tag, '📝 过滤后Delta操作数量: ${visibleOperations.length}');
      return jsonEncode(visibleDeltaJson);
      
    } catch (e) {
      AppLogger.e(_tag, '获取可见Delta JSON失败', e);
      return jsonEncode(controller.document.toDelta().toJson()); // 回退到原始Delta
    }
  }

  /// 🎯 检查文档是否包含任何AI生成内容
  static bool hasAnyAIGeneratedContent({
    required QuillController controller,
  }) {
    try {
      final ranges = getAIGeneratedRanges(controller: controller);
      return ranges.isNotEmpty;
    } catch (e) {
      AppLogger.e(_tag, '检查AI生成内容失败', e);
      return false;
    }
  }

  /// 🆕 检查文档是否包含任何隐藏文本
  static bool hasAnyHiddenText({
    required QuillController controller,
  }) {
    try {
      final ranges = getHiddenTextRanges(controller: controller);
      return ranges.isNotEmpty;
    } catch (e) {
      AppLogger.e(_tag, '检查隐藏文本失败', e);
      return false;
    }
  }
} 