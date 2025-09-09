import 'dart:async';

import 'package:ainoval/config/app_config.dart';
import 'package:ainoval/services/api_service/base/api_client.dart';
import 'package:ainoval/services/api_service/base/api_exception.dart';
import 'package:ainoval/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';


/// 用户认证服务
/// 
/// 负责用户登录、注册、令牌管理等认证相关功能
class AuthService {
  
  AuthService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient() {
    // 设置ApiClient的AuthService实例（避免循环依赖）
    _apiClient.setAuthService(this);
  }
  
  final ApiClient _apiClient;
  
  // 存储令牌的键
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  
  // 认证状态流
  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  // 当前认证状态
  AuthState _currentState = AuthState.unauthenticated();
  AuthState get currentState => _currentState;
  
  /// 初始化认证服务
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token != null) {
      final userId = prefs.getString(_userIdKey);
      final username = prefs.getString(_usernameKey);
      
      // 设置认证状态
      _currentState = AuthState.authenticated(
        token: token,
        userId: userId ?? '',
        username: username ?? '',
      );
      
      // 设置全局认证令牌、用户ID和用户名
      AppConfig.setAuthToken(token);
      AppConfig.setUserId(userId);
      AppConfig.setUsername(username);
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
    }
  }
  
  /// 用户登录
  Future<AuthState> login(String username, String password) async {
    try {
      final data = await _apiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final userId = data['userId'];
      
      // 保存令牌到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      
      // 设置全局认证令牌、用户ID和用户名
      AppConfig.setAuthToken(token);
      AppConfig.setUserId(userId);
      AppConfig.setUsername(username);
      
      // 更新认证状态
      _currentState = AuthState.authenticated(
        token: token,
        userId: userId,
        username: username,
      );
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
      
      return _currentState;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('登录失败: $e');
    }
  }
  
  /// 用户注册
  Future<AuthState> register(String username, String password, String email, {String? displayName}) async {
    try {
      await _apiClient.post('/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
        'displayName': displayName ?? username,
      });
      
      // 注册成功后自动登录
      return login(username, password);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('注册失败: $e');
    }
  }
  
  /// 用户注册（带验证）
  Future<AuthState> registerWithVerification({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? displayName,
    String? captchaId,
    String? captchaCode,
    String? emailVerificationCode,
    String? phoneVerificationCode,
  }) async {
    try {
      final data = await _apiClient.post('/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
        'phone': phone,
        'displayName': displayName ?? username,
        'captchaId': captchaId,
        'captchaCode': captchaCode,
        'emailVerificationCode': emailVerificationCode,
        'phoneVerificationCode': phoneVerificationCode,
      });
      
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final userId = data['userId'];
      
      // 保存令牌到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      
      // 设置全局认证令牌、用户ID和用户名
      AppConfig.setAuthToken(token);
      AppConfig.setUserId(userId);
      AppConfig.setUsername(username);
      
      // 更新认证状态
      _currentState = AuthState.authenticated(
        token: token,
        userId: userId,
        username: username,
      );
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
      
      return _currentState;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('注册失败: $e');
    }
  }
  
  /// 快捷注册（用户名 + 密码）
  Future<AuthState> registerQuick({
    required String username,
    required String password,
    String? displayName,
  }) async {
    try {
      final data = await _apiClient.post('/auth/register/quick', data: {
        'username': username,
        'password': password,
        'displayName': displayName ?? username,
      });
      
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final userId = data['userId'];
      
      // 保存令牌到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      
      // 设置全局认证令牌、用户ID和用户名
      AppConfig.setAuthToken(token);
      AppConfig.setUserId(userId);
      AppConfig.setUsername(username);
      
      // 更新认证状态
      _currentState = AuthState.authenticated(
        token: token,
        userId: userId,
        username: username,
      );
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
      
      return _currentState;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('注册失败: $e');
    }
  }
  
  /// 手机号登录
  Future<AuthState> loginWithPhone({
    required String phone,
    required String verificationCode,
  }) async {
    try {
      final data = await _apiClient.post('/auth/login/phone', data: {
        'phone': phone,
        'verificationCode': verificationCode,
      });
      
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final userId = data['userId'];
      final username = data['username'];
      
      // 保存令牌到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      
      // 设置全局认证令牌、用户ID和用户名
      AppConfig.setAuthToken(token);
      AppConfig.setUserId(userId);
      AppConfig.setUsername(username);
      
      // 更新认证状态
      _currentState = AuthState.authenticated(
        token: token,
        userId: userId,
        username: username,
      );
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
      
      return _currentState;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('登录失败: $e');
    }
  }
  
  /// 邮箱登录
  Future<AuthState> loginWithEmail({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final data = await _apiClient.post('/auth/login/email', data: {
        'email': email,
        'verificationCode': verificationCode,
      });
      
      final token = data['token'];
      final refreshToken = data['refreshToken'];
      final userId = data['userId'];
      final username = data['username'];
      
      // 保存令牌到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      
      // 设置全局认证令牌、用户ID和用户名
      AppConfig.setAuthToken(token);
      AppConfig.setUserId(userId);
      AppConfig.setUsername(username);
      
      // 更新认证状态
      _currentState = AuthState.authenticated(
        token: token,
        userId: userId,
        username: username,
      );
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
      
      return _currentState;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('登录失败: $e');
    }
  }
  
  /// 发送验证码（登录时使用，不需要图片验证码）
  Future<bool> sendVerificationCode({
    required String type,
    required String target,
    required String purpose,
  }) async {
    try {
      await _apiClient.post('/auth/verification-code', data: {
        'type': type,
        'target': target,
        'purpose': purpose,
      });
      
      return true;
    } on ApiException catch (e) {
      // 将后端的错误信息透传给上层
      AppLogger.w('Services/auth_service', '发送验证码失败: ${e.message}');
      throw AuthException(e.message);
    } catch (e) {
      AppLogger.e('Services/auth_service', '发送验证码异常', e);
      throw AuthException('验证码发送失败: $e');
    }
  }

  /// 发送验证码（注册时使用，需要先验证图片验证码）
  Future<bool> sendVerificationCodeWithCaptcha({
    required String type,
    required String target,
    required String purpose,
    required String captchaId,
    required String captchaCode,
  }) async {
    try {
      final requestData = {
        'type': type,
        'target': target,
        'purpose': purpose,
        'captchaId': captchaId,
        'captchaCode': captchaCode,
      };
      
      AppLogger.i('Services/auth_service', '🚀 发送验证码请求');
      AppLogger.d('Services/auth_service', '📝 请求参数: $requestData');
      
      final response = await _apiClient.post('/auth/verification-code', data: requestData);
      
      AppLogger.i('Services/auth_service', '📬 API响应内容: $response');
      AppLogger.i('Services/auth_service', '✅ 验证码发送成功（HTTP 200）');
      return true;
    } on ApiException catch (e) {
      AppLogger.w('Services/auth_service', '❌ 验证码发送失败: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      AppLogger.e('Services/auth_service', '💥 发送验证码异常', e);
      rethrow;
    }
  }
  
  /// 加载图片验证码
  Future<Map<String, String>?> loadCaptcha() async {
    try {
      AppLogger.i('Services/auth_service', '🖼️ 请求图片验证码');
      
      final response = await _apiClient.post('/auth/captcha');
      
      AppLogger.i('Services/auth_service', '✅ 图片验证码加载成功');
      return {
        'captchaId': response['captchaId'],
        'captchaImage': response['captchaImage'],
      };
    } on ApiException catch (e) {
      AppLogger.w('Services/auth_service', '❌ 图片验证码加载失败: ${e.message}');
      return null;
    } catch (e) {
      AppLogger.e('Services/auth_service', '💥 加载图片验证码异常', e);
      return null;
    }
  }
  
  /// 用户登出
  Future<void> logout() async {
    try {
      // 立即清除本地数据，不等待后端响应（JWT无状态特性）
      final token = AppConfig.authToken;

      // 异步调用后端logout接口，不阻塞退出流程
      if (token != null) {
        // 使用fire-and-forget模式，不等待响应
        _callLogoutEndpoint(token).catchError((e) {
          AppLogger.w('Services/auth_service', '后端登出请求失败', e);
        });
      }

      // 清除本地存储的令牌
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      
      // 清除全局认证令牌、用户ID和用户名
      AppConfig.setAuthToken(null);
      AppConfig.setUserId(null);
      AppConfig.setUsername(null);
      
      // 更新认证状态
      _currentState = AuthState.unauthenticated();
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
      
      AppLogger.i('Services/auth_service', '用户登出成功');
    } catch (e) {
      AppLogger.e('Services/auth_service', '登出失败', e);
      // 即使出错也要清除本地状态
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userIdKey);
        await prefs.remove(_usernameKey);
        
        AppConfig.setAuthToken(null);
        AppConfig.setUserId(null);
        AppConfig.setUsername(null);
        
        _currentState = AuthState.unauthenticated();
        _authStateController.add(_currentState);
      } catch (cleanupError) {
        AppLogger.e('Services/auth_service', '清除本地认证状态失败', cleanupError);
      }
    }
  }
  
  /// 刷新令牌
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (refreshToken == null) {
        return false;
      }
      
      final data = await _apiClient.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      
      final newToken = data['token'];
      final newRefreshToken = data['refreshToken'];
      
      // 保存新令牌到本地存储
      await prefs.setString(_tokenKey, newToken);
      await prefs.setString(_refreshTokenKey, newRefreshToken);
      
      // 设置全局认证令牌
      AppConfig.setAuthToken(newToken);
      
      // 更新认证状态
      final userId = prefs.getString(_userIdKey) ?? '';
      final username = prefs.getString(_usernameKey) ?? '';
      
      // 设置用户ID和用户名
      AppConfig.setUserId(userId);
      AppConfig.setUsername(username);
      
      _currentState = AuthState.authenticated(
        token: newToken,
        userId: userId,
        username: username,
      );
      
      // 发送认证状态更新
      _authStateController.add(_currentState);
      
      return true;
    } on ApiException {
      // 刷新令牌失败，清除认证状态
      await logout();
      return false;
    } catch (e) {
      AppLogger.e('Services/auth_service', '刷新令牌失败', e);
      // 刷新令牌失败，清除认证状态
      await logout();
      return false;
    }
  }
  
  /// 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    if (!_currentState.isAuthenticated) {
      throw AuthException('用户未登录');
    }
    
    try {
      // 由于ApiClient会自动添加Authorization头，我们直接调用即可
      final data = await _apiClient.get('/users/${_currentState.userId}');
      return data;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // 令牌过期，尝试刷新
        final refreshed = await refreshToken();
        if (refreshed) {
          // 刷新成功，重试
          return getCurrentUser();
        } else {
          throw AuthException('认证已过期，请重新登录');
        }
      } else {
        throw AuthException(e.message);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('获取用户信息失败: $e');
    }
  }
  
  /// 更新用户信息
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    if (!_currentState.isAuthenticated) {
      throw AuthException('用户未登录');
    }
    
    try {
      final data = await _apiClient.put('/users/${_currentState.userId}', data: profileData);
      return data;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // 令牌过期，尝试刷新
        final refreshed = await refreshToken();
        if (refreshed) {
          // 刷新成功，重试
          return updateUserProfile(profileData);
        } else {
          throw AuthException('认证已过期，请重新登录');
        }
      } else {
        throw AuthException(e.message);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('更新用户信息失败: $e');
    }
  }
  
  /// 修改密码
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (!_currentState.isAuthenticated) {
      throw AuthException('用户未登录');
    }
    
    try {
      await _apiClient.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'username': AppConfig.username, // 确保后端能识别当前用户
      });
      // 密码修改成功
      return;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // 令牌过期，尝试刷新
        final refreshed = await refreshToken();
        if (refreshed) {
          // 刷新成功，重试
          return changePassword(currentPassword, newPassword);
        } else {
          throw AuthException('认证已过期，请重新登录');
        }
      } else {
        throw AuthException(e.message);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('修改密码失败: $e');
    }
  }




  /// 异步调用后端登出接口（fire-and-forget模式）
  Future<void> _callLogoutEndpoint(String token) async {
    // 创建临时的Headers选项，包含token
    final options = Options(headers: {
      'Authorization': 'Bearer $token',
    });
    
    final request = _apiClient.post('/auth/logout', options: options).timeout(
      Duration(seconds: 3), // 设置3秒超时
      onTimeout: () {
        AppLogger.w('Services/auth_service', '后端登出请求超时');
        throw TimeoutException('Logout request timeout', Duration(seconds: 3));
      },
    );

    try {
      await request;
      AppLogger.i('Services/auth_service', '后端登出成功');
    } on ApiException catch (e) {
      AppLogger.w('Services/auth_service', '后端登出失败: ${e.message}');
    } catch (e) {
      AppLogger.w('Services/auth_service', '后端登出请求异常', e);
    }
  }
  
  /// 关闭服务
  void dispose() {
    _authStateController.close();
  }
}

/// 认证状态类
class AuthState {
  
  AuthState({
    required this.isAuthenticated,
    this.token = '',
    this.userId = '',
    this.username = '',
    this.error,
  });
  
  /// 已认证状态
  factory AuthState.authenticated({
    required String token,
    required String userId,
    required String username,
  }) {
    return AuthState(
      isAuthenticated: true,
      token: token,
      userId: userId,
      username: username,
    );
  }
  
  /// 未认证状态
  factory AuthState.unauthenticated() {
    return AuthState(isAuthenticated: false);
  }
  
  /// 认证错误状态
  factory AuthState.error(String errorMessage) {
    return AuthState(
      isAuthenticated: false,
      error: errorMessage,
    );
  }
  final bool isAuthenticated;
  final String token;
  final String userId;
  final String username;
  final String? error;
}

/// 认证异常类
class AuthException implements Exception {
  
  AuthException(this.message);
  final String message;
  
  @override
  String toString() => 'AuthException: $message';
} 