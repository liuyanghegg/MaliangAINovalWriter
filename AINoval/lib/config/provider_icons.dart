import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 图标尺寸枚举
enum IconSize {
  small,      // 16px
  medium,     // 24px
  large,      // 32px
  extraLarge, // 48px
}

/// AI模型提供商图标管理类
/// 提供统一的图标获取接口
class ProviderIcons {
  // 私有构造函数，防止实例化
  ProviderIcons._();

  /// 提供商图标路径映射表
  static const Map<String, String> _providerIconPaths = {
    // OpenAI系列
    'openai': 'assets/icons/openai.svg',
    'chatgpt': 'assets/icons/openai.svg',
    'gpt': 'assets/icons/openai.svg',
    
    // Anthropic系列
    'anthropic': 'assets/icons/anthropic.svg',
    'claude': 'assets/icons/claude-color.svg',
    
    // Google系列
    'google': 'assets/icons/gemini-color.svg',
    'gemini': 'assets/icons/gemini-color.svg',
    'bard': 'assets/icons/gemini-color.svg',
    
    // 微软系列
    'microsoft': 'assets/icons/microsoft-color.svg',
    'azure': 'assets/icons/microsoft-color.svg',
    'copilot': 'assets/icons/microsoft-color.svg',
    
    // Meta系列
    'meta': 'assets/icons/meta-color.svg',
    'llama': 'assets/icons/meta-color.svg',
    'facebook': 'assets/icons/meta-color.svg',
    
    // 字节跳动系列
    'bytedance': 'assets/icons/bytedance-color.svg',
    'doubao': 'assets/icons/doubao-color.svg',
    '豆包': 'assets/icons/doubao-color.svg',
    
    // 智谱AI系列
    'zhipu': 'assets/icons/zhipu-color.svg',
    'glm': 'assets/icons/zhipu-color.svg',
    '智谱': 'assets/icons/zhipu-color.svg',
    
    // 阿里系列
    'qwen': 'assets/icons/qwen-color.svg',
    'tongyi': 'assets/icons/qwen-color.svg',
    'alibaba': 'assets/icons/qwen-color.svg',
    '通义': 'assets/icons/qwen-color.svg',
    
    // DeepSeek系列
    'deepseek': 'assets/icons/deepseek-color.svg',
    
    // Mistral系列
    'mistral': 'assets/icons/mistral-color.svg',
    
    // 硅基流动
    'siliconcloud': 'assets/icons/siliconcloud-color.svg',
    'siliconflow': 'assets/icons/siliconcloud-color.svg',
    
    // Perplexity
    'perplexity': 'assets/icons/perplexity-color.svg',
    
    // HuggingFace
    'huggingface': 'assets/icons/huggingface-color.svg',
    'hf': 'assets/icons/huggingface-color.svg',
    
    // Stability AI
    'stability': 'assets/icons/stability-color.svg',
    'stable-diffusion': 'assets/icons/stability-color.svg',
    
    // OpenRouter
    'openrouter': 'assets/icons/openrouter.svg',
    
    // Ollama
    'ollama': 'assets/icons/ollama.svg',
    
    // xAI Grok
    'xai': 'assets/icons/grok.svg',
    'grok': 'assets/icons/grok.svg',
        // xAI Grok
    'x-ai': 'assets/icons/grok.svg',
    'X-ai': 'assets/icons/grok.svg',
    
    
    // Midjourney
    'midjourney': 'assets/icons/midjourney.svg',
    'mj': 'assets/icons/midjourney.svg',
    
    // LM Studio
    'lm-studio': 'assets/icons/ollama.svg',
    'lmstudio': 'assets/icons/ollama.svg',
    
    // LocalAI
    'localai': 'assets/icons/ollama.svg',
    'local': 'assets/icons/ollama.svg',
  };

  /// 提供商默认颜色映射
  /// 颜色配置参考: https://lobehub.com/zh/icons
  static const Map<String, Color> _providerColors = {
    // OpenAI系列 - #000
    'openai': Color(0xFF000000),
    'chatgpt': Color(0xFF000000),
    'gpt': Color(0xFF000000),
    
    // Anthropic系列 - #F1F0E8 (浅色背景) / Claude: #D97757
    'anthropic': Color(0xFFF1F0E8),
    'claude': Color(0xFFD97757),
    
    // Google系列 - #1C69FF (Gemini) / #FFF (Google)
    'google': Color(0xFFFFFFFF),
    'gemini': Color(0xFF1C69FF),
    'bard': Color(0xFF1C69FF),
    
    // 微软系列 - #00A4EF / Copilot: #FFF
    'microsoft': Color(0xFF00A4EF),
    'azure': Color(0xFF00A4EF),
    'copilot': Color(0xFFFFFFFF),
    
    // Meta系列 - #1D65C1
    'meta': Color(0xFF1D65C1),
    'llama': Color(0xFF1D65C1),
    'facebook': Color(0xFF1D65C1),
    
    // 字节跳动系列 - #325AB4 / Doubao: #FFF
    'bytedance': Color(0xFF325AB4),
    'doubao': Color(0xFFFFFFFF),
    '豆包': Color(0xFFFFFFFF),
    
    // 智谱AI系列 - #3859FF / ChatGLM: #4268FA
    'zhipu': Color(0xFF3859FF),
    'glm': Color(0xFF4268FA),
    '智谱': Color(0xFF3859FF),
    
    // 阿里系列 - #615CED
    'qwen': Color(0xFF615CED),
    'tongyi': Color(0xFF615CED),
    'alibaba': Color(0xFF615CED),
    '通义': Color(0xFF615CED),
    
    // DeepSeek系列
    'deepseek': Color(0xFF4D6BFE),
    
    // Mistral系列 - #FA520F
    'mistral': Color(0xFFFA520F),
    
    // 硅基流动
    'siliconcloud': Color(0xFF7C3AED),
    'siliconflow': Color(0xFF7C3AED),
    
    // Perplexity - #22B8CD
    'perplexity': Color(0xFF22B8CD),
    
    // HuggingFace - #FFF
    'huggingface': Color(0xFFFFFFFF),
    'hf': Color(0xFFFFFFFF),
    
    // Stability AI - #330066
    'stability': Color(0xFF330066),
    'stable-diffusion': Color(0xFF330066),
    
    // OpenRouter - #6566F1
    'openrouter': Color(0xFF6566F1),
    
    // Ollama - #FFF
    'ollama': Color(0xFFFFFFFF),
    
    // xAI Grok - #000
    'xai': Color(0xFF000000),
    'grok': Color(0xFF000000),
    'x-ai': Color(0xFF000000),
    'X-ai': Color(0xFF000000),
    
    // Midjourney - #FFF
    'midjourney': Color(0xFFFFFFFF),
    'mj': Color(0xFFFFFFFF),
    
    // Groq - #F55036
    'groq': Color(0xFFF55036),
    
    // together.ai - #0F6FFF
    'together': Color(0xFF0F6FFF),
    'together.ai': Color(0xFF0F6FFF),
    
    // Fireworks - #5019C5
    'fireworks': Color(0xFF5019C5),
    
    // Cohere - #39594D
    'cohere': Color(0xFF39594D),
    
    // Replicate - #EA2805
    'replicate': Color(0xFFEA2805),
    
    // LM Studio / LocalAI
    'lm-studio': Color(0xFFFFFFFF),
    'lmstudio': Color(0xFFFFFFFF),
    'localai': Color(0xFFFFFFFF),
    'local': Color(0xFFFFFFFF),
  };

  /// 获取提供商图标（优化版本）
  /// 
  /// [provider] 提供商名称，大小写不敏感
  /// [size] 图标大小，默认为24（提高默认尺寸提升清晰度）
  /// [color] 图标颜色，如果不指定则使用默认颜色
  /// [useHighQuality] 是否使用高质量渲染，默认为true
  static Widget getProviderIcon(
    String provider, {
    double size = 24, // 提高默认尺寸
    Color? color,
    bool useHighQuality = true,
  }) {
    final normalizedProvider = provider.toLowerCase().trim();
    final iconPath = _providerIconPaths[normalizedProvider];
    
    if (iconPath != null) {
      // 首先尝试加载 SVG 格式
      if (iconPath.endsWith('.svg')) {
        return SvgPicture.asset(
          iconPath,
          width: size,
          height: size,
          colorFilter: color != null 
            ? ColorFilter.mode(color, BlendMode.srcIn) 
            : null,
          placeholderBuilder: (context) => _getDefaultIcon(
            provider, 
            size: size, 
            color: color,
          ),
        );
      } else {
        // 优化的 PNG 加载配置
        return Image.asset(
          iconPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: color,
          // 启用高质量过滤器，减少模糊
          filterQuality: useHighQuality ? FilterQuality.high : FilterQuality.medium,
          // 禁用抗锯齿可能导致的模糊
          isAntiAlias: true,
          errorBuilder: (context, error, stackTrace) {
            return _getDefaultIcon(provider, size: size, color: color);
          },
        );
      }
    } else {
      // 如果没有找到对应图标，使用默认图标
      return _getDefaultIcon(provider, size: size, color: color);
    }
  }

  /// 获取提供商图标（指定尺寸版本）
  /// 对于不同使用场景提供不同的尺寸建议
  static Widget getProviderIconForContext(
    String provider, {
    required IconSize iconSize,
    Color? color,
  }) {
    double size;
    switch (iconSize) {
      case IconSize.small:
        size = 16;
        break;
      case IconSize.medium:
        size = 24;
        break;
      case IconSize.large:
        size = 32;
        break;
      case IconSize.extraLarge:
        size = 48;
        break;
    }
    
    return getProviderIcon(
      provider,
      size: size,
      color: color,
      useHighQuality: true,
    );
  }

  /// 获取提供商默认颜色
  static Color getProviderColor(String provider) {
    final normalizedProvider = provider.toLowerCase().trim();
    return _providerColors[normalizedProvider] ?? Colors.grey;
  }

  /// 获取默认图标（当找不到对应图标时使用）
  static Widget _getDefaultIcon(
    String provider, {
    required double size,
    Color? color,
  }) {
    final normalizedProvider = provider.toLowerCase().trim();
    
    IconData iconData;
    Color iconColor = color ?? getProviderColor(provider);

    // 根据提供商名称选择合适的Material Icon作为备用
    if (normalizedProvider.contains('openai') || 
        normalizedProvider.contains('gpt') || 
        normalizedProvider.contains('chatgpt')) {
      iconData = Icons.auto_awesome;
    } else if (normalizedProvider.contains('anthropic') || 
               normalizedProvider.contains('claude')) {
      iconData = Icons.psychology;
    } else if (normalizedProvider.contains('google') || 
               normalizedProvider.contains('gemini') || 
               normalizedProvider.contains('bard')) {
      iconData = Icons.star;
    } else if (normalizedProvider.contains('openrouter')) {
      iconData = Icons.router;
    } else if (normalizedProvider.contains('ollama') || 
               normalizedProvider.contains('local')) {
      iconData = Icons.computer;
    } else if (normalizedProvider.contains('microsoft') || 
               normalizedProvider.contains('azure') ||
               normalizedProvider.contains('copilot')) {
      iconData = Icons.science;
    } else if (normalizedProvider.contains('meta') || 
               normalizedProvider.contains('llama') ||
               normalizedProvider.contains('facebook')) {
      iconData = Icons.groups;
    } else if (normalizedProvider.contains('bytedance') || 
               normalizedProvider.contains('doubao')) {
      iconData = Icons.smart_toy;
    } else if (normalizedProvider.contains('zhipu') || 
               normalizedProvider.contains('glm')) {
      iconData = Icons.lightbulb;
    } else if (normalizedProvider.contains('qwen') || 
               normalizedProvider.contains('tongyi') ||
               normalizedProvider.contains('alibaba')) {
      iconData = Icons.cloud;
    } else if (normalizedProvider.contains('deepseek')) {
      iconData = Icons.search;
    } else if (normalizedProvider.contains('mistral')) {
      iconData = Icons.air;
    } else if (normalizedProvider.contains('silicon')) {
      iconData = Icons.memory;
    } else if (normalizedProvider.contains('perplexity')) {
      iconData = Icons.quiz;
    } else if (normalizedProvider.contains('huggingface') || 
               normalizedProvider.contains('hf')) {
      iconData = Icons.emoji_emotions;
    } else if (normalizedProvider.contains('stability') || 
               normalizedProvider.contains('stable')) {
      iconData = Icons.image;
    } else if (normalizedProvider.contains('midjourney') || 
               normalizedProvider.contains('mj')) {
      iconData = Icons.palette;
    } else if (normalizedProvider.contains('xai') || 
               normalizedProvider.contains('grok')) {
      iconData = Icons.explore;
    } else if (normalizedProvider.contains('groq')) {
      iconData = Icons.speed;
    } else if (normalizedProvider.contains('together')) {
      iconData = Icons.group_work;
    } else if (normalizedProvider.contains('fireworks')) {
      iconData = Icons.celebration;
    } else if (normalizedProvider.contains('cohere')) {
      iconData = Icons.link;
    } else if (normalizedProvider.contains('replicate')) {
      iconData = Icons.replay;
    } else {
      iconData = Icons.api;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: size,
    );
  }

  /// 检查是否支持某个提供商
  static bool isSupported(String provider) {
    final normalizedProvider = provider.toLowerCase().trim();
    return _providerIconPaths.containsKey(normalizedProvider);
  }

  /// 获取所有支持的提供商列表
  static List<String> getSupportedProviders() {
    return _providerIconPaths.keys.toList();
  }

  /// 获取提供商的显示名称
  static String getProviderDisplayName(String provider) {
    final normalizedProvider = provider.toLowerCase().trim();
    
    const displayNames = {
      'openai': 'OpenAI',
      'chatgpt': 'ChatGPT',
      'gpt': 'GPT',
      'anthropic': 'Anthropic',
      'claude': 'Claude',
      'google': 'Google',
      'gemini': 'Gemini',
      'bard': 'Bard',
      'microsoft': 'Microsoft',
      'azure': 'Azure',
      'copilot': 'Copilot',
      'meta': 'Meta',
      'llama': 'Llama',
      'facebook': 'Facebook',
      'bytedance': '字节跳动',
      'doubao': '豆包',
      'zhipu': '智谱AI',
      'glm': 'GLM',
      'qwen': '通义千问',
      'tongyi': '通义千问',
      'alibaba': '阿里巴巴',
      'deepseek': 'DeepSeek',
      'mistral': 'Mistral',
      'siliconcloud': '硅基流动',
      'siliconflow': '硅基流动',
      'perplexity': 'Perplexity',
      'huggingface': 'Hugging Face',
      'hf': 'Hugging Face',
      'stability': 'Stability AI',
      'stable-diffusion': 'Stable Diffusion',
      'openrouter': 'OpenRouter',
      'ollama': 'Ollama',
      'xai': 'xAI',
      'grok': 'Grok',
      'x-ai': 'xAI',
      'X-ai': 'xAI',
      'midjourney': 'Midjourney',
      'mj': 'Midjourney',
      'groq': 'Groq',
      'together': 'Together AI',
      'together.ai': 'Together AI',
      'fireworks': 'Fireworks AI',
      'cohere': 'Cohere',
      'replicate': 'Replicate',
      'lm-studio': 'LM Studio',
      'lmstudio': 'LM Studio',
      'localai': 'LocalAI',
      'local': 'Local',
    };
    
    return displayNames[normalizedProvider] ?? _capitalizeFirst(provider);
  }

  /// 首字母大写
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
} 