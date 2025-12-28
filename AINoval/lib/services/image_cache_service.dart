import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ainoval/utils/logger.dart';

/// 图片缓存服务
/// 负责处理用户设置的图片缓存、自适应显示和内存管理
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // 内存缓存映射
  final Map<String, ui.Image> _memoryCache = {};
  final Map<String, ImageInfo> _imageInfoCache = {};
  
  // 缓存限制
  static const int _maxCacheSize = 50; // 最大缓存图片数量
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB内存限制
  
  int _currentMemoryUsage = 0;

  /// 获取自适应图片组件
  Widget getAdaptiveImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    double? aspectRatio,
  }) {
    return FutureBuilder<ui.Image?>(
      future: _loadAndCacheImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildAdaptiveImageWidget(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            aspectRatio: aspectRatio,
          );
        }
        
        // 显示占位符或加载指示器
        return _buildPlaceholder(
          width: width,
          height: height,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          isLoading: !snapshot.hasError,
          placeholder: placeholder,
        );
      },
    );
  }

  /// 构建自适应图片组件
  Widget _buildAdaptiveImageWidget(
    ui.Image image, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    double? aspectRatio,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      child: CustomPaint(
        painter: _AdaptiveImagePainter(
          image: image,
          fit: fit,
          aspectRatio: aspectRatio,
        ),
        size: Size(width, height),
      ),
    );
  }

  /// 构建占位符
  Widget _buildPlaceholder({
    required double width,
    required double height,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool isLoading = false,
    String? placeholder,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Icon(
              Icons.broken_image,
              color: Colors.grey[400],
              size: math.min(width, height) * 0.3,
            ),
    );
  }

  /// 加载并缓存图片
  Future<ui.Image?> _loadAndCacheImage(String imageUrl) async {
    try {
      // 检查内存缓存
      if (_memoryCache.containsKey(imageUrl)) {
        AppLogger.d('ImageCache', '从内存缓存加载图片: $imageUrl');
        return _memoryCache[imageUrl];
      }

      // 加载图片
      ui.Image? image;
      
      if (imageUrl.startsWith('http')) {
        // 网络图片
        image = await _loadNetworkImage(imageUrl);
      } else if (imageUrl.startsWith('assets/')) {
        // 资源图片
        image = await _loadAssetImage(imageUrl);
      } else {
        // 本地文件图片
        image = await _loadFileImage(imageUrl);
      }

      if (image != null) {
        await _cacheImage(imageUrl, image);
      }

      return image;
    } catch (e) {
      AppLogger.e('ImageCache', '加载图片失败: $imageUrl', e);
      return null;
    }
  }

  /// 加载网络图片
  Future<ui.Image?> _loadNetworkImage(String url) async {
    try {
      final NetworkImage provider = NetworkImage(url);
      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      final Completer<ui.Image> completer = Completer<ui.Image>();
      
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          completer.completeError(exception, stackTrace);
          stream.removeListener(listener);
        },
      );
      
      stream.addListener(listener);
      return await completer.future;
    } catch (e) {
      AppLogger.e('ImageCache', '加载网络图片失败: $url', e);
      return null;
    }
  }

  /// 加载资源图片
  Future<ui.Image?> _loadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      AppLogger.e('ImageCache', '加载资源图片失败: $assetPath', e);
      return null;
    }
  }

  /// 加载本地文件图片
  Future<ui.Image?> _loadFileImage(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      AppLogger.e('ImageCache', '加载本地图片失败: $filePath', e);
      return null;
    }
  }

  /// 缓存图片
  Future<void> _cacheImage(String key, ui.Image image) async {
    // 检查缓存大小限制
    if (_memoryCache.length >= _maxCacheSize) {
      _evictOldestCache();
    }

    // 估算图片内存使用
    final int imageBytes = image.width * image.height * 4; // RGBA
    
    // 检查内存限制
    if (_currentMemoryUsage + imageBytes > _maxMemoryUsage) {
      await _evictCacheToFitMemory(imageBytes);
    }

    _memoryCache[key] = image;
    _currentMemoryUsage += imageBytes;
    
    AppLogger.d('ImageCache', 
        '缓存图片: $key, 尺寸: ${image.width}x${image.height}, 内存使用: ${_currentMemoryUsage ~/ 1024}KB');
  }

  /// 移除最旧的缓存
  void _evictOldestCache() {
    if (_memoryCache.isNotEmpty) {
      final String firstKey = _memoryCache.keys.first;
      final ui.Image? image = _memoryCache.remove(firstKey);
      if (image != null) {
        final int imageBytes = image.width * image.height * 4;
        _currentMemoryUsage -= imageBytes;
        image.dispose();
      }
      _imageInfoCache.remove(firstKey);
    }
  }

  /// 移除缓存以腾出内存空间
  Future<void> _evictCacheToFitMemory(int requiredBytes) async {
    while (_currentMemoryUsage + requiredBytes > _maxMemoryUsage && 
           _memoryCache.isNotEmpty) {
      _evictOldestCache();
    }
  }

  /// 清理所有缓存
  void clearCache() {
    for (final ui.Image image in _memoryCache.values) {
      image.dispose();
    }
    _memoryCache.clear();
    _imageInfoCache.clear();
    _currentMemoryUsage = 0;
    AppLogger.i('ImageCache', '清理所有图片缓存');
  }

  /// 预加载图片
  Future<void> preloadImage(String imageUrl) async {
    if (!_memoryCache.containsKey(imageUrl)) {
      await _loadAndCacheImage(imageUrl);
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _memoryCache.length,
      'memoryUsage': _currentMemoryUsage,
      'memoryUsageKB': _currentMemoryUsage ~/ 1024,
      'memoryUsageMB': _currentMemoryUsage ~/ (1024 * 1024),
    };
  }
}

/// 自适应图片绘制器
class _AdaptiveImagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;
  final double? aspectRatio;

  _AdaptiveImagePainter({
    required this.image,
    required this.fit,
    this.aspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double imageAspectRatio = image.width / image.height;
    final double containerAspectRatio = size.width / size.height;
    
    Rect srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    Rect dstRect;

    switch (fit) {
      case BoxFit.cover:
        if (imageAspectRatio > containerAspectRatio) {
          // 图片更宽，裁剪左右
          final double newWidth = image.height * containerAspectRatio;
          final double offsetX = (image.width - newWidth) / 2;
          srcRect = Rect.fromLTWH(offsetX, 0, newWidth, image.height.toDouble());
        } else {
          // 图片更高，裁剪上下
          final double newHeight = image.width / containerAspectRatio;
          final double offsetY = (image.height - newHeight) / 2;
          srcRect = Rect.fromLTWH(0, offsetY, image.width.toDouble(), newHeight);
        }
        dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
        break;
        
      case BoxFit.contain:
        if (imageAspectRatio > containerAspectRatio) {
          // 图片更宽，适应宽度
          final double newHeight = size.width / imageAspectRatio;
          final double offsetY = (size.height - newHeight) / 2;
          dstRect = Rect.fromLTWH(0, offsetY, size.width, newHeight);
        } else {
          // 图片更高，适应高度
          final double newWidth = size.height * imageAspectRatio;
          final double offsetX = (size.width - newWidth) / 2;
          dstRect = Rect.fromLTWH(offsetX, 0, newWidth, size.height);
        }
        break;
        
      case BoxFit.fill:
      default:
        dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
        break;
    }

    // 使用高质量图片渲染
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;
      
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _AdaptiveImagePainter ||
           oldDelegate.image != image ||
           oldDelegate.fit != fit ||
           oldDelegate.aspectRatio != aspectRatio;
  }
}

