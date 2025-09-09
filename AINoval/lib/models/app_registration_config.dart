import 'package:shared_preferences/shared_preferences.dart';

/// 应用注册配置
/// 管理注册功能的开关和设置
class AppRegistrationConfig {
  static const String _phoneRegistrationEnabledKey = 'phone_registration_enabled';
  static const String _emailRegistrationEnabledKey = 'email_registration_enabled';
  static const String _requireVerificationKey = 'require_verification';
  static const String _quickRegistrationEnabledKey = 'quick_registration_enabled';
  
  // 默认配置（MVP：仅快捷注册）
  static const bool _defaultPhoneRegistrationEnabled = false;  // 关闭手机注册
  static const bool _defaultEmailRegistrationEnabled = false;  // 关闭邮箱注册
  static const bool _defaultRequireVerification = false;        // 关闭验证码
  static const bool _defaultQuickRegistrationEnabled = true;    // 开启快捷注册
  
  // 缓存配置
  static bool? _cachedPhoneRegistrationEnabled;
  static bool? _cachedEmailRegistrationEnabled;
  static bool? _cachedRequireVerification;
  static bool? _cachedQuickRegistrationEnabled;
  
  /// 获取是否启用快捷注册
  static Future<bool> isQuickRegistrationEnabled() async {
    if (_cachedQuickRegistrationEnabled != null) {
      return _cachedQuickRegistrationEnabled!;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedQuickRegistrationEnabled = prefs.getBool(_quickRegistrationEnabledKey) ?? _defaultQuickRegistrationEnabled;
    return _cachedQuickRegistrationEnabled!;
  }
  
  /// 设置是否启用快捷注册
  static Future<void> setQuickRegistrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quickRegistrationEnabledKey, enabled);
    _cachedQuickRegistrationEnabled = enabled;
  }
  
  /// 获取是否启用手机注册
  static Future<bool> isPhoneRegistrationEnabled() async {
    if (_cachedPhoneRegistrationEnabled != null) {
      return _cachedPhoneRegistrationEnabled!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _cachedPhoneRegistrationEnabled = prefs.getBool(_phoneRegistrationEnabledKey) ?? _defaultPhoneRegistrationEnabled;
    return _cachedPhoneRegistrationEnabled!;
  }
  
  /// 设置是否启用手机注册
  static Future<void> setPhoneRegistrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_phoneRegistrationEnabledKey, enabled);
    _cachedPhoneRegistrationEnabled = enabled;
  }
  
  /// 获取是否启用邮箱注册
  static Future<bool> isEmailRegistrationEnabled() async {
    if (_cachedEmailRegistrationEnabled != null) {
      return _cachedEmailRegistrationEnabled!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _cachedEmailRegistrationEnabled = prefs.getBool(_emailRegistrationEnabledKey) ?? _defaultEmailRegistrationEnabled;
    return _cachedEmailRegistrationEnabled!;
  }
  
  /// 设置是否启用邮箱注册
  static Future<void> setEmailRegistrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailRegistrationEnabledKey, enabled);
    _cachedEmailRegistrationEnabled = enabled;
  }
  
  /// 获取是否需要验证
  static Future<bool> isVerificationRequired() async {
    if (_cachedRequireVerification != null) {
      return _cachedRequireVerification!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    _cachedRequireVerification = prefs.getBool(_requireVerificationKey) ?? _defaultRequireVerification;
    return _cachedRequireVerification!;
  }
  
  /// 设置是否需要验证
  static Future<void> setVerificationRequired(bool required) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requireVerificationKey, required);
    _cachedRequireVerification = required;
  }
  
  /// 获取可用的注册方式列表
  static Future<List<RegistrationMethod>> getAvailableRegistrationMethods() async {
    final List<RegistrationMethod> methods = [];
    
    if (await isEmailRegistrationEnabled()) {
      methods.add(RegistrationMethod.email);
    }
    
    if (await isPhoneRegistrationEnabled()) {
      methods.add(RegistrationMethod.phone);
    }
    
    return methods;
  }
  
  /// 检查是否至少有一种注册方式可用
  static Future<bool> hasAvailableRegistrationMethod() async {
    final methods = await getAvailableRegistrationMethods();
    return methods.isNotEmpty;
  }
  
  /// 重置所有配置到默认值
  static Future<void> resetToDefaults() async {
    await setPhoneRegistrationEnabled(_defaultPhoneRegistrationEnabled);
    await setEmailRegistrationEnabled(_defaultEmailRegistrationEnabled);
    await setVerificationRequired(_defaultRequireVerification);
    await setQuickRegistrationEnabled(_defaultQuickRegistrationEnabled);
  }
  
  /// 清除缓存
  static void clearCache() {
    _cachedPhoneRegistrationEnabled = null;
    _cachedEmailRegistrationEnabled = null;
    _cachedRequireVerification = null;
    _cachedQuickRegistrationEnabled = null;
  }
}

/// 注册方式枚举
enum RegistrationMethod {
  email('邮箱注册', 'email'),
  phone('手机注册', 'phone');
  
  const RegistrationMethod(this.displayName, this.value);
  
  final String displayName;
  final String value;
}

/// 注册配置数据类
class RegistrationConfig {
  const RegistrationConfig({
    required this.phoneRegistrationEnabled,
    required this.emailRegistrationEnabled,
    required this.verificationRequired,
    this.quickRegistrationEnabled = true,
  });
  
  final bool phoneRegistrationEnabled;
  final bool emailRegistrationEnabled;
  final bool verificationRequired;
  final bool quickRegistrationEnabled;
  
  /// 获取可用的注册方式
  List<RegistrationMethod> get availableMethods {
    final List<RegistrationMethod> methods = [];
    
    if (emailRegistrationEnabled) {
      methods.add(RegistrationMethod.email);
    }
    
    if (phoneRegistrationEnabled) {
      methods.add(RegistrationMethod.phone);
    }
    
    return methods;
  }
  
  /// 是否至少有一种注册方式可用
  bool get hasAvailableMethod => availableMethods.isNotEmpty;
  
  /// 复制配置
  RegistrationConfig copyWith({
    bool? phoneRegistrationEnabled,
    bool? emailRegistrationEnabled,
    bool? verificationRequired,
    bool? quickRegistrationEnabled,
  }) {
    return RegistrationConfig(
      phoneRegistrationEnabled: phoneRegistrationEnabled ?? this.phoneRegistrationEnabled,
      emailRegistrationEnabled: emailRegistrationEnabled ?? this.emailRegistrationEnabled,
      verificationRequired: verificationRequired ?? this.verificationRequired,
      quickRegistrationEnabled: quickRegistrationEnabled ?? this.quickRegistrationEnabled,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegistrationConfig &&
        other.phoneRegistrationEnabled == phoneRegistrationEnabled &&
        other.emailRegistrationEnabled == emailRegistrationEnabled &&
        other.verificationRequired == verificationRequired &&
        other.quickRegistrationEnabled == quickRegistrationEnabled;
  }
  
  @override
  int get hashCode => Object.hash(
    phoneRegistrationEnabled,
    emailRegistrationEnabled,
    verificationRequired,
    quickRegistrationEnabled,
  );
}
