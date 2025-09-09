import 'dart:convert';
import 'dart:math' as math;
import 'package:ainoval/utils/logger.dart';

/// Quill富文本编辑器格式处理工具类
/// 
/// 用于统一处理Quill富文本编辑器的内容格式，确保正确转换和验证Delta格式
class QuillHelper {
  static const String _tag = 'QuillHelper';

  /// 确保内容是标准的Quill格式
  /// 
  /// 将{"ops":[...]}格式转换为更简洁的[...]格式
  /// 将非JSON文本转换为基本的Quill格式
  /// 
  /// @param content 输入的内容
  /// @return 标准化后的Quill Delta格式
  static String ensureQuillFormat(String content) {
    if (content.isEmpty) {
      return jsonEncode([{"insert": "\n"}]);
    }
    
    try {
      // 检查内容是否是纯文本（不是JSON格式）
      try {
        jsonDecode(content);
      } catch (e) {
        // 如果解析失败，说明是纯文本，直接转换为Delta格式
        return jsonEncode([{"insert": "$content\n"}]);
      }
      
      // 尝试解析为JSON，检查是否已经是Quill格式
      final dynamic parsed = jsonDecode(content);
      
      // 如果已经是数组格式，检查是否符合Quill格式要求
      if (parsed is List) {
        List<Map<String, dynamic>> ops = parsed.cast<Map<String, dynamic>>();
        bool isValidQuill = ops.isNotEmpty && 
                           ops.every((item) => item is Map && (item.containsKey('insert') || item.containsKey('attributes')));
        
        if (isValidQuill) {
          // 🚀 新增：检查和记录样式属性保存情况
          bool hasStyleAttributes = false;
          for (final op in ops) {
            if (op.containsKey('attributes')) {
              hasStyleAttributes = true;
              final attributes = op['attributes'] as Map<String, dynamic>?;
              if (attributes != null && (attributes.containsKey('color') || attributes.containsKey('background'))) {
                AppLogger.d('QuillHelper/ensureQuillFormat', 
                    '🎨 保存样式属性: ${attributes.keys.join(', ')}');
              }
            }
          }
          
          if (hasStyleAttributes) {
            AppLogger.i('QuillHelper/ensureQuillFormat', 
                '🎨 确保包含样式属性的Quill格式，操作数量: ${ops.length}');
          }
          
          // 确保最后一个操作以换行符结尾
          if (ops.isNotEmpty) {
            final lastOp = ops.last;
            if (lastOp.containsKey('insert')) {
              final insertText = lastOp['insert'].toString();
              if (!insertText.endsWith('\n')) {
                // 如果最后一个insert不以换行符结尾，添加一个新的换行符操作
                ops.add({'insert': '\n'});
              }
            } else {
              // 如果最后一个操作不包含insert，添加换行符
              ops.add({'insert': '\n'});
            }
          }
          return jsonEncode(ops); // 返回修正后的Quill格式
        } else {
          // 转换为纯文本后重新格式化
          String plainText = _extractTextFromList(parsed);
          return jsonEncode([{"insert": "$plainText\n"}]);
        }
      } 
      
      // 如果是对象格式，检查是否符合Delta格式
      if (parsed is Map && parsed.containsKey('ops') && parsed['ops'] is List) {
        List<Map<String, dynamic>> ops = (parsed['ops'] as List).cast<Map<String, dynamic>>();
        
        // 确保最后一个操作以换行符结尾
        if (ops.isNotEmpty) {
          final lastOp = ops.last;
          if (lastOp.containsKey('insert')) {
            final insertText = lastOp['insert'].toString();
            if (!insertText.endsWith('\n')) {
              // 如果最后一个insert不以换行符结尾，添加一个新的换行符操作
              ops.add({'insert': '\n'});
            }
          } else {
            // 如果最后一个操作不包含insert，添加换行符
            ops.add({'insert': '\n'});
          }
        } else {
          // 如果ops为空，添加一个换行符
          ops = [{'insert': '\n'}];
        }
        
        return jsonEncode(ops);
      }
      
      // 其他JSON格式，转换为纯文本
      return jsonEncode([{"insert": "${jsonEncode(parsed)}\n"}]);
    } catch (e) {
      // 不是JSON格式，作为纯文本处理
      AppLogger.w('QuillHelper', '内容不是标准格式，作为纯文本处理');
      // 转义特殊字符，确保JSON格式有效
      String safeText = content
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll('\t', '\\t');
      
      return jsonEncode([{"insert": "$safeText\n"}]);
    }
  }

  /// 将纯文本内容转换为Quill Delta格式
  /// 
  /// @param text 纯文本内容
  /// @return Quill Delta格式的字符串
  static String textToDelta(String text) {
    if (text.isEmpty) {
      return standardEmptyDelta;
    }
    
    final String escapedText = _escapeQuillText(text);
    return '[{"insert":"$escapedText\\n"}]';
  }

  /// 将Quill Delta格式转换为纯文本
  /// 
  /// @param delta Quill Delta格式的字符串
  /// @return 纯文本内容
  static String deltaToText(String deltaContent) {
    try {
      final dynamic parsed = jsonDecode(deltaContent);
      
      if (parsed is List) {
        return _extractTextFromList(parsed);
      } else if (parsed is Map && parsed.containsKey('ops') && parsed['ops'] is List) {
        return _extractTextFromList(parsed['ops'] as List);
      }
      
      // 如果不是标准格式，返回原始内容
      return deltaContent;
    } catch (e) {
      // 如果解析失败，返回原始内容
      return deltaContent;
    }
  }

  /// 验证内容是否为有效的Quill格式
  /// 
  /// @param content 要验证的内容
  /// @return 是否为有效的Quill格式
  static bool isValidQuillFormat(String content) {
    try {
      final parsed = jsonDecode(content);
      if (parsed is List) {
        return parsed.every((item) => item is Map && item.containsKey('insert'));
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取标准的空Quill Delta格式
  static String get standardEmptyDelta => '[{"insert":"\\n"}]';
  
  /// 获取包含ops的空Quill Delta格式
  static String get opsWrappedEmptyDelta => '{"ops":[{"insert":"\\n"}]}';

  /// 转义Quill文本中的特殊字符
  static String _escapeQuillText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');
  }
  
  /// 检测内容格式，确定是否需要转换
  /// 
  /// @param content 输入的内容
  /// @return 是否需要转换为标准格式
  static bool needsFormatConversion(String content) {
    if (content.isEmpty) {
      return true;
    }
    
    try {
      final dynamic contentJson = jsonDecode(content);
      return contentJson is Map && contentJson.containsKey('ops');
    } catch (e) {
      return !content.startsWith('[{');
    }
  }
  
  /// 计算Quill Delta内容的字数统计
  /// 
  /// @param delta Quill Delta格式的字符串
  /// @return 内容的字数
  static int countWords(String delta) {
    final String text = deltaToText(delta);
    if (text.isEmpty) {
      return 0;
    }
    
    // 移除所有换行符后计算字数
    final String cleanText = text.replaceAll('\n', '');
    return cleanText.length;
  }

  /// 从List中提取文本内容
  static String _extractTextFromList(List list) {
    StringBuffer buffer = StringBuffer();
    for (var item in list) {
      if (item is Map && item.containsKey('insert')) {
        buffer.write(item['insert']);
      } else if (item is String) {
        buffer.write(item);
      } else {
        buffer.write(jsonEncode(item));
      }
    }
    return buffer.toString();
  }

  /// 将纯文本转换为Quill Delta格式
  static String convertPlainTextToQuillDelta(String text) {
    if (text.isEmpty) {
      return jsonEncode([{"insert": "\n"}]);
    }
    
    // 处理换行符，确保JSON格式正确
    String safeText = text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
    
    // 构建基本的Quill格式
    return jsonEncode([{"insert": "$safeText\n"}]);
  }

  /// 验证并修复Delta格式
  /// 
  /// 确保Delta格式符合Flutter Quill的要求，特别是最后一个操作必须以换行符结尾
  /// 
  /// @param deltaJson Delta格式的JSON字符串
  /// @return 修复后的有效Delta格式
  static String validateAndFixDelta(String deltaJson) {
    if (deltaJson.isEmpty) {
      return jsonEncode([{"insert": "\n"}]);
    }
    
    try {
      final dynamic parsed = jsonDecode(deltaJson);
      List<Map<String, dynamic>> ops;
      
      if (parsed is List) {
        ops = parsed.cast<Map<String, dynamic>>();
      } else if (parsed is Map && parsed.containsKey('ops') && parsed['ops'] is List) {
        ops = (parsed['ops'] as List).cast<Map<String, dynamic>>();
      } else {
        // 不是有效的Delta格式，转换为纯文本
        return jsonEncode([{"insert": "$deltaJson\n"}]);
      }
      
      // 确保最后一个操作以换行符结尾
      if (ops.isEmpty) {
        ops = [{"insert": "\n"}];
      } else {
        final lastOp = ops.last;
        if (lastOp.containsKey('insert')) {
          final insertText = lastOp['insert'].toString();
          if (!insertText.endsWith('\n')) {
            // 如果最后一个insert不以换行符结尾，添加一个新的换行符操作
            ops.add({"insert": "\n"});
          }
        } else {
          // 如果最后一个操作不包含insert，添加换行符
          ops.add({"insert": "\n"});
        }
      }
      
      return jsonEncode(ops);
    } catch (e) {
      // 解析失败，作为纯文本处理
      AppLogger.w('QuillHelper', 'Delta验证失败，转换为纯文本: ${e.toString()}');
      return jsonEncode([{"insert": "$deltaJson\n"}]);
    }
  }

  /// 🚀 新增：测试样式属性的保存和解析
  /// 
  /// 用于验证包含颜色、背景等样式属性的内容是否能正确保存和加载
  static Map<String, dynamic> testStyleAttributeHandling() {
    final testResults = <String, dynamic>{};
    
    try {
      // 测试数据：包含各种样式属性的Quill内容
      final testContents = [
        // 1. 包含背景颜色的内容
        '[{"insert":"这是红色背景的文字","attributes":{"background":"#f44336"}},{"insert":"\\n"}]',
        
        // 2. 包含文字颜色的内容
        '[{"insert":"这是蓝色的文字","attributes":{"color":"#2196f3"}},{"insert":"\\n"}]',
        
        // 3. 包含多种样式的内容
        '[{"insert":"粗体红色背景","attributes":{"bold":true,"background":"#f44336"}},{"insert":" 普通文字 "},{"insert":"蓝色斜体","attributes":{"color":"#2196f3","italic":true}},{"insert":"\\n"}]',
        
        // 4. ops格式的内容
        '{"ops":[{"insert":"绿色背景文字","attributes":{"background":"#4caf50"}},{"insert":"\\n"}]}',
      ];
      
      final results = <Map<String, dynamic>>[];
      
      for (int i = 0; i < testContents.length; i++) {
        final testContent = testContents[i];
        final testName = 'Test${i + 1}';
        
        AppLogger.i('QuillHelper/testStyleAttributeHandling', 
            '🧪 开始测试 $testName: ${testContent.length} 字符');
        
        try {
          // 1. 测试ensureQuillFormat处理
          final processedContent = ensureQuillFormat(testContent);
          
          // 2. 解析处理后的内容
          final parsedData = jsonDecode(processedContent);
          
          // 3. 检查样式属性是否保留
          bool foundStyles = false;
          final foundAttributes = <String, dynamic>{};
          
          if (parsedData is List) {
            for (final op in parsedData) {
              if (op is Map && op.containsKey('attributes')) {
                foundStyles = true;
                final attributes = op['attributes'] as Map<String, dynamic>;
                foundAttributes.addAll(attributes);
              }
            }
          }
          
          results.add({
            'testName': testName,
            'originalLength': testContent.length,
            'processedLength': processedContent.length,
            'foundStyles': foundStyles,
            'attributes': foundAttributes,
            'success': foundStyles,
            'originalContent': testContent.substring(0, math.min(100, testContent.length)),
            'processedContent': processedContent.substring(0, math.min(100, processedContent.length)),
          });
          
          AppLogger.i('QuillHelper/testStyleAttributeHandling', 
              '✅ $testName 成功: 找到样式=$foundStyles, 属性=${foundAttributes.keys.join(',')}');
              
        } catch (e) {
          results.add({
            'testName': testName,
            'success': false,
            'error': e.toString(),
          });
          
          AppLogger.e('QuillHelper/testStyleAttributeHandling', 
              '❌ $testName 失败: $e');
        }
      }
      
      // 汇总结果
      final successCount = results.where((r) => r['success'] == true).length;
      final totalCount = results.length;
      
      testResults['summary'] = {
        'totalTests': totalCount,
        'successCount': successCount,
        'failureCount': totalCount - successCount,
        'successRate': totalCount > 0 ? (successCount / totalCount * 100).toStringAsFixed(1) + '%' : '0%',
      };
      
      testResults['details'] = results;
      testResults['overallSuccess'] = successCount == totalCount;
      
      AppLogger.i('QuillHelper/testStyleAttributeHandling', 
          '🏁 测试完成: $successCount/$totalCount 成功 (${testResults['summary']['successRate']})');
      
    } catch (e) {
      testResults['error'] = e.toString();
      testResults['overallSuccess'] = false;
      
      AppLogger.e('QuillHelper/testStyleAttributeHandling', 
          '💥 测试过程出错: $e');
    }
    
    return testResults;
  }


} 