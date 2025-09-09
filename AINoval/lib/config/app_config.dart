import 'dart:io';

import 'package:flutter/foundation.dart';

// 条件导入：在非Web平台导入dart:io，在Web平台导入dart:html

/// 应用环境枚举
enum Environment {
  development,
  production,
}

/// 应用配置类
/// 
/// 用于管理应用的环境配置和模拟数据设置
class AppConfig {
  /// 私有构造函数，防止实例化
  AppConfig._();
  
  /// 当前环境
  static Environment _environment = kDebugMode ? Environment.development : Environment.production;
  
  /// 是否强制使用模拟数据（无论环境如何）
  static bool _forceMockData = false;
  
  /// 是否为管理员模式
  static bool _isAdminMode = false;
  
  /// 获取当前环境
  static Environment get environment => _environment;
  
  /// 设置当前环境
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  /// 是否应该使用模拟数据
  static bool get shouldUseMockData => _forceMockData;
  
  /// 强制使用/不使用模拟数据
  static void setUseMockData(bool useMock) {
    _forceMockData = useMock;
  }
  
  /// 获取是否为管理员模式
  static bool get isAdminMode => _isAdminMode;
  
  /// 设置管理员模式
  static void setAdminMode(bool isAdmin) {
    _isAdminMode = isAdmin;
  }

  /// 检查是否为Android平台（仅在非Web平台有效）
  static bool get _isAndroid {
    if (kIsWeb) {
      return false;
    }
    try {
      // 只有在非Web平台才能访问Platform
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }
  
  /// API基础URL
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        // 在Web平台上，直接使用localhost
        if (kIsWeb) {
          return 'http://127.0.0.1:18080/api/v1';
        }
        // 在Android平台上，使用10.0.2.2来访问宿主机
        // 在其他平台上使用127.0.0.1
        else if (_isAndroid) {
          return 'http://10.0.2.2:18080/api/v1';
        } else {
          return 'http://127.0.0.1:18080/api/v1';
        }
      case Environment.production:
        return '/api/v1';
    }
  }
  
  /// API认证令牌
  static String? _authToken;
  
  /// 设置认证令牌
  static void setAuthToken(String? token) {
    _authToken = token;
  }
  
  /// 获取认证令牌
  static String? get authToken => _authToken;
  
  /// 当前用户ID
  static String? _userId;
  
  /// 设置当前用户ID
  static void setUserId(String? id) {
    _userId = id;
  }
  
  /// 获取当前用户ID
  static String? get userId => _userId;
  
  /// 当前用户名
  static String? _username;
  
  /// 设置当前用户名
  static void setUsername(String? name) {
    _username = name;
  }
  
  /// 获取当前用户名
  static String? get username => _username;
  
  /// 日志级别
  static LogLevel get logLevel {
    switch (_environment) {
      case Environment.development:
        return LogLevel.debug;
      case Environment.production:
        return LogLevel.error;
    }
  }
  
  // 当前编辑/阅读的小说ID
  static String? currentNovelId;
  
  // 应用版本信息
  static String appVersion = '1.0.0';
  static bool isDebugMode = kDebugMode;
  
  // 初始化配置
  static Future<void> initialize() async {
    // 这里可以从本地存储或其他来源加载配置
  }
  
  // 保存用户状态
  static Future<void> saveUserState() async {
    // 将用户状态保存到本地存储
  }
  
  // 清除用户状态
  static Future<void> clearUserState() async {
    _userId = null;
    _username = null;
    _authToken = null;
  }
  
  // 设置当前小说
  static void setCurrentNovel(String? id) {
    currentNovelId = id;
  }
}

/// 日志级别枚举
enum LogLevel {
  debug,   // 调试信息
  info,    // 一般信息
  warning, // 警告信息
  error,   // 错误信息
} 