import 'dart:convert';

/// 内容格式化工具类
/// 智能识别文本内容类型并进行相应的格式化
class ContentFormatter {
  
  /// 格式化内容
  /// 
  /// 自动检测内容类型并应用相应的格式化
  /// 
  /// 支持的格式：
  /// - XML（默认优先）
  /// - JSON
  /// - YAML
  /// - Markdown
  /// - 普通文本（保持原样）
  static FormattedContent formatContent(String content) {
    if (content.trim().isEmpty) {
      return FormattedContent(
        content: content,
        type: ContentType.xml, // 默认为XML类型
        formatted: content,
      );
    }

    // 优先检测和格式化XML
    final xmlResult = _tryFormatXml(content);
    if (xmlResult != null) {
      return xmlResult;
    }

    // 检测和格式化JSON
    final jsonResult = _tryFormatJson(content);
    if (jsonResult != null) {
      return jsonResult;
    }

    // 检测YAML格式
    final yamlResult = _tryDetectYaml(content);
    if (yamlResult != null) {
      return yamlResult;
    }

    // 检测Markdown格式
    final markdownResult = _tryDetectMarkdown(content);
    if (markdownResult != null) {
      return markdownResult;
    }

    // 默认为XML格式（即使不是标准XML也使用XML高亮）
    return FormattedContent(
      content: content,
      type: ContentType.xml,
      formatted: _formatAsXml(content),
    );
  }

  /// 尝试格式化XML内容
  static FormattedContent? _tryFormatXml(String content) {
    final trimmed = content.trim();
    
    // XML检测：宽松检测，包含标签特征即认为是XML
    if (_looksLikeXml(trimmed)) {
      try {
        final formatted = _formatXmlString(trimmed);
        
        return FormattedContent(
          content: content,
          type: ContentType.xml,
          formatted: formatted,
        );
      } catch (e) {
        // 即使格式化失败，仍然作为XML处理
        return FormattedContent(
          content: content,
          type: ContentType.xml,
          formatted: trimmed,
        );
      }
    }
    
    return null;
  }

  /// 检查内容是否看起来像XML
  static bool _looksLikeXml(String content) {
    // 宽松的XML检测
    if (content.contains('<') && content.contains('>')) {
      // 检查是否包含XML标签模式
      final xmlTagPattern = RegExp(r'<[^>]+>');
      return xmlTagPattern.hasMatch(content);
    }
    return false;
  }

  /// 将任何内容格式化为XML样式
  static String _formatAsXml(String content) {
    // 如果内容不包含XML标签，将其包装在XML标签中
    if (!_looksLikeXml(content)) {
      return '<content>\n${content.split('\n').map((line) => '  $line').join('\n')}\n</content>';
    }
    
    // 如果已经是XML样式，尝试格式化
    try {
      return _formatXmlString(content);
    } catch (e) {
      return content;
    }
  }

  /// 尝试格式化JSON内容
  static FormattedContent? _tryFormatJson(String content) {
    final trimmed = content.trim();
    
    // 基本JSON检测（仅在明确是JSON时才处理）
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        // 尝试解析JSON
        final dynamic parsed = jsonDecode(trimmed);
        
        // 格式化JSON
        const encoder = JsonEncoder.withIndent('  ');
        final formatted = encoder.convert(parsed);
        
        return FormattedContent(
          content: content,
          type: ContentType.json,
          formatted: formatted,
        );
      } catch (e) {
        // 不是有效的JSON，返回null让其他格式处理
        return null;
      }
    }
    
    return null;
  }

  /// 尝试检测YAML内容
  static FormattedContent? _tryDetectYaml(String content) {
    final lines = content.split('\n');
    bool hasYamlPattern = false;
    
    // 检测YAML特征（只有明确的YAML模式才识别）
    for (String line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      // YAML键值对模式（更严格的检测）
      if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*\s*:\s*[^<>]+$').hasMatch(trimmed)) {
        hasYamlPattern = true;
        break;
      }
      
      // YAML列表模式
      if (RegExp(r'^\s*-\s+[^<>]+$').hasMatch(trimmed)) {
        hasYamlPattern = true;
        break;
      }
    }
    
    // 确保不是XML内容被误认为YAML
    if (hasYamlPattern && !_looksLikeXml(content)) {
      return FormattedContent(
        content: content,
        type: ContentType.yaml,
        formatted: content, // YAML通常已经是格式化的
      );
    }
    
    return null;
  }

  /// 尝试检测Markdown内容
  static FormattedContent? _tryDetectMarkdown(String content) {
    final lines = content.split('\n');
    bool hasMarkdownPattern = false;
    
    // 检测Markdown特征（只有明确的Markdown模式才识别）
    for (String line in lines) {
      final trimmed = line.trim();
      
      // Markdown标题
      if (RegExp(r'^#{1,6}\s+.+').hasMatch(trimmed)) {
        hasMarkdownPattern = true;
        break;
      }
      
      // Markdown代码块
      if (trimmed.startsWith('```')) {
        hasMarkdownPattern = true;
        break;
      }
      
      // Markdown链接（更严格的检测）
      if (RegExp(r'\[.+\]\(.+\)').hasMatch(trimmed)) {
        hasMarkdownPattern = true;
        break;
      }
    }
    
    // 确保不是XML内容被误认为Markdown
    if (hasMarkdownPattern && !_looksLikeXml(content)) {
      return FormattedContent(
        content: content,
        type: ContentType.markdown,
        formatted: content,
      );
    }
    
    return null;
  }

  /// 改进的XML格式化
  static String _formatXmlString(String xml) {
    final buffer = StringBuffer();
    int indent = 0;
    bool inTag = false;
    bool inClosingTag = false;
    bool inText = false;
    
    String currentLine = '';
    
    for (int i = 0; i < xml.length; i++) {
      final char = xml[i];
      
      if (char == '<') {
        // 处理之前积累的文本内容
        if (inText && currentLine.trim().isNotEmpty) {
          buffer.writeln('${'  ' * indent}${currentLine.trim()}');
          currentLine = '';
        }
        inText = false;
        
        // 检查是否是闭合标签
        if (xml.length > i + 1 && xml[i + 1] == '/') {
          inClosingTag = true;
          indent = (indent - 1).clamp(0, 100);
        }
        
        // 添加缩进和标签开始
        if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
          buffer.writeln();
        }
        buffer.write('${'  ' * indent}<');
        inTag = true;
        
        // 如果不是闭合标签，增加缩进
        if (!inClosingTag) {
          indent++;
        }
      } else if (char == '>') {
        buffer.write(char);
        inTag = false;
        inClosingTag = false;
        
        // 检查下一个字符，决定是否换行
        if (i < xml.length - 1) {
          final nextChar = xml[i + 1];
          if (nextChar == '<') {
            buffer.writeln();
          } else if (nextChar.trim().isNotEmpty) {
            inText = true;
            currentLine = '';
          }
        }
      } else {
        if (inText) {
          currentLine += char;
        } else {
          buffer.write(char);
        }
      }
    }
    
    // 处理最后的文本内容
    if (inText && currentLine.trim().isNotEmpty) {
      buffer.writeln('${'  ' * indent}${currentLine.trim()}');
    }
    
    return buffer.toString().trim();
  }
}

/// 格式化后的内容
class FormattedContent {
  const FormattedContent({
    required this.content,
    required this.type,
    required this.formatted,
  });

  /// 原始内容
  final String content;
  
  /// 内容类型
  final ContentType type;
  
  /// 格式化后的内容
  final String formatted;
}

/// 内容类型枚举（XML优先）
enum ContentType {
  xml('XML'),
  json('JSON'),
  yaml('YAML'),
  markdown('Markdown'),
  plain('文本');

  const ContentType(this.displayName);
  
  final String displayName;
} 