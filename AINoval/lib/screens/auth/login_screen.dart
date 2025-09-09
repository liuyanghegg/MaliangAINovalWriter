import 'dart:async';
import 'dart:io';
import 'package:ainoval/blocs/auth/auth_bloc.dart';
import 'package:ainoval/models/app_registration_config.dart';
import 'package:ainoval/screens/novel_list/novel_list_real_data_screen.dart';
import 'package:ainoval/widgets/common/theme_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ainoval/widgets/common/top_toast.dart';

/// 登录页面
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _captchaController = TextEditingController();

  bool _isLogin = true; // 是否为登录模式
  String _loginMethod = 'username'; // 登录方式: username, phone, email
  RegistrationMethod? _registrationMethod; // 注册方式: email, phone
  String? _captchaId;
  String? _captchaImage;
  bool _isVerificationCodeSent = false;
  int _countdown = 0;
  bool _hasNetworkConnection = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  RegistrationConfig? _registrationConfig;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadRegistrationConfig();
    if (!_isLogin) {
      _loadCaptcha();
    }
    _initNetworkListener();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    _captchaController.dispose();
    _connectivitySubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 初始化网络连接监听
  void _initNetworkListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = results.any((result) => result != ConnectivityResult.none);
        if (mounted) {
          setState(() {
            _hasNetworkConnection = isConnected;
          });
          if (!isConnected) {
            _showNetworkError();
          }
        }
      },
    );
  }

  /// 检查网络连接
  Future<bool> _checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 显示网络错误提示
  void _showNetworkError() {
    TopToast.warning(context, '网络连接已断开，请检查您的网络连接');
    () async {
      final isConnected = await _checkNetworkConnection();
      if (mounted) {
        setState(() { _hasNetworkConnection = isConnected; });
        if (isConnected) {
          TopToast.success(context, '网络连接已恢复');
        }
      }
    }();
  }

  /// 加载注册配置
  Future<void> _loadRegistrationConfig() async {
    final config = RegistrationConfig(
      phoneRegistrationEnabled: await AppRegistrationConfig.isPhoneRegistrationEnabled(),
      emailRegistrationEnabled: await AppRegistrationConfig.isEmailRegistrationEnabled(),
      verificationRequired: await AppRegistrationConfig.isVerificationRequired(),
      quickRegistrationEnabled: await AppRegistrationConfig.isQuickRegistrationEnabled(),
    );
    
    setState(() {
      _registrationConfig = config;
      // 设置默认注册方式为第一个可用的方式
      if (config.availableMethods.isNotEmpty) {
        _registrationMethod = config.availableMethods.first;
      }
    });
  }

  /// 切换登录/注册模式
  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _loginMethod = 'username'; // 重置登录方式
      if (!_isLogin) {
        if (!(_registrationConfig?.quickRegistrationEnabled ?? true)) {
          _loadCaptcha(); // 需要验证码的注册才加载
        }
        // 设置默认注册方式
        if (_registrationConfig != null && _registrationConfig!.availableMethods.isNotEmpty) {
          _registrationMethod = _registrationConfig!.availableMethods.first;
        }
      }
    });
    _formKey.currentState?.reset(); // 重置表单验证状态
  }

  /// 加载图片验证码
  Future<void> _loadCaptcha() async {
    final authBloc = context.read<AuthBloc>();
    authBloc.add(LoadCaptcha());
  }

  /// 发送验证码
  Future<void> _sendVerificationCode() async {
    final authBloc = context.read<AuthBloc>();
    
    String type = '';
    String target = '';
    
    if (_isLogin) {
      // 登录时的验证码发送
      if (_loginMethod == 'phone') {
        type = 'phone';
        target = _phoneController.text;
        if (!RegExp(r'^1[3-9]\d{9}').hasMatch(target)) {
          _showError('请输入正确的手机号');
          return;
        }
      } else if (_loginMethod == 'email') {
        type = 'email';
        target = _emailController.text;
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(target)) {
          _showError('请输入正确的邮箱地址');
          return;
        }
      }
    } else {
      // 注册时的验证码发送（快捷注册不开启验证码）
      if (_registrationConfig?.quickRegistrationEnabled ?? true) {
        return;
      }
      if (_registrationMethod == RegistrationMethod.email) {
        type = 'email';
        target = _emailController.text;
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(target)) {
          _showError('请输入正确的邮箱地址');
          return;
        }
      } else if (_registrationMethod == RegistrationMethod.phone) {
        type = 'phone';
        target = _phoneController.text;
        if (!RegExp(r'^1[3-9]\d{9}').hasMatch(target)) {
          _showError('请输入正确的手机号');
          return;
        }
      }
    }
    
    if (type.isNotEmpty) {
      authBloc.add(SendVerificationCode(
        type: type,
        target: target,
        purpose: _isLogin ? 'login' : 'register',
      ));
      
      // 开始倒计时
      _startCountdown();
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() {
      _isVerificationCodeSent = true;
      _countdown = 60;
    });
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isVerificationCodeSent = false;
        });
      }
    });
  }

  /// 显示错误消息
  void _showError(String message) {
    TopToast.error(context, message);
  }

  /// 提交表单 - 改为向 AuthBloc 发送事件
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // 检查网络连接
      if (!_hasNetworkConnection) {
        final isConnected = await _checkNetworkConnection();
        if (!isConnected) {
          _showError('请检查您的网络连接后再试');
          return;
        } else {
          setState(() {
            _hasNetworkConnection = true;
          });
        }
      }

      // 获取 AuthBloc 实例
      final authBloc = context.read<AuthBloc>();

      if (_isLogin) {
        // 根据登录方式发送不同的登录事件
        switch (_loginMethod) {
          case 'phone':
            authBloc.add(PhoneLogin(
              phone: _phoneController.text,
              verificationCode: _verificationCodeController.text,
            ));
            break;
          case 'email':
            authBloc.add(EmailLogin(
              email: _emailController.text,
              verificationCode: _verificationCodeController.text,
            ));
            break;
          default:
            authBloc.add(AuthLogin(
              username: _usernameController.text,
              password: _passwordController.text,
            ));
        }
      } else {
        // 注册
        final quick = _registrationConfig?.quickRegistrationEnabled ?? true;
        if (quick) {
          // 仅用户名 + 密码
          authBloc.add(AuthRegister(
            username: _usernameController.text,
            password: _passwordController.text,
            email: null,
            phone: null,
            displayName: _usernameController.text,
            captchaId: null,
            captchaCode: null,
            emailVerificationCode: null,
            phoneVerificationCode: null,
          ));
        } else {
          // 旧流程
          String? email;
          String? phone;
          String? emailVerificationCode;
          String? phoneVerificationCode;
          
          if (_registrationMethod == RegistrationMethod.email) {
            email = _emailController.text;
            emailVerificationCode = _verificationCodeController.text;
          } else if (_registrationMethod == RegistrationMethod.phone) {
            phone = _phoneController.text;
            phoneVerificationCode = _verificationCodeController.text;
          }
          
          // 发送注册事件
          authBloc.add(AuthRegister(
            username: _usernameController.text,
            password: _passwordController.text,
            email: email,
            phone: phone,
            displayName: _usernameController.text,
            captchaId: _captchaId,
            captchaCode: _captchaController.text,
            emailVerificationCode: emailVerificationCode,
            phoneVerificationCode: phoneVerificationCode,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final quick = _registrationConfig?.quickRegistrationEnabled ?? true;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            curr is AuthAuthenticated || curr is AuthUnauthenticated,
        listener: (context, state) {
          // --- 处理认证成功后的导航 ---
          if (state is AuthAuthenticated) {
            // 确保在 widget 仍然挂载时执行导航
            if (mounted) {
              // 导航到小说列表页面
              // 使用 pushReplacement 避免用户返回登录页
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const NovelListRealDataScreen()),
              );
            }
          }
        },
        buildWhen: (prev, curr) =>
            curr is AuthAuthenticated || curr is AuthUnauthenticated,
        builder: (context, state) {
          // 根据 BLoC 状态判断是否显示加载状态
          final bool isLoading = state is AuthLoading;
          // 从 BLoC 状态获取错误信息
          final String? errorMessage = state is AuthError ? state.message : null;
          
          // 处理验证码状态
          if (state is CaptchaLoaded) {
            _captchaId = state.captchaId;
            _captchaImage = state.captchaImage;
          }

          return Stack(
            children: [
              // 主题切换按钮放在右上角
              Positioned(
                top: 50,
                right: 20,
                child: const ThemeToggleButton(),
              ),
              // 原有的登录表单内容
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                Icons.biotech,
                                size: 60,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'AINoval',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isLogin ? '登录您的创作平台' : '加入AINoval开始创作',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '测试阶段福利：注册即送300积分',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              if (errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.error.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getErrorIcon(errorMessage),
                                            color: theme.colorScheme.onErrorContainer,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              errorMessage,
                                              style: TextStyle(
                                                color: theme.colorScheme.onErrorContainer,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_shouldShowRetryButton(errorMessage)) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: isLoading ? null : () {
                                                _retryLastAction();
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: theme.colorScheme.onErrorContainer,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 4,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.refresh, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text('重试'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                              // 登录方式选择（仅登录时显示）
                              if (_isLogin) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ChoiceChip(
                                      label: Text('用户名'),
                                      selected: _loginMethod == 'username',
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _loginMethod = 'username';
                                          });
                                        }
                                      },
                                    ),
                                    ChoiceChip(
                                      label: Text('手机号'),
                                      selected: _loginMethod == 'phone',
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _loginMethod = 'phone';
                                          });
                                        }
                                      },
                                    ),
                                    ChoiceChip(
                                      label: Text('邮箱'),
                                      selected: _loginMethod == 'email',
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _loginMethod = 'email';
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // 根据登录方式或注册模式显示不同的输入字段
                              if (_isLogin && _loginMethod == 'username') ...[
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: '用户名',
                                    prefixIcon: Icon(Icons.person_outline,
                                        color: theme.iconTheme.color?.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 12.0),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入用户名';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: '密码',
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: theme.iconTheme.color?.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 12.0),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入密码';
                                    }
                                    return null;
                                  },
                                ),
                              ] else if (_isLogin && _loginMethod == 'phone') ...[
                                // 保持原有手机号验证码登录
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: '手机号',
                                    prefixIcon: Icon(Icons.phone_outlined,
                                        color: theme.iconTheme.color?.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 12.0),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入手机号';
                                    }
                                    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                                      return '请输入正确的手机号';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _verificationCodeController,
                                        decoration: InputDecoration(
                                          labelText: '验证码',
                                          prefixIcon: Icon(Icons.lock_outline,
                                              color: theme.iconTheme.color?.withOpacity(0.7)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          filled: true,
                                          fillColor:
                                              isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                          contentPadding: const EdgeInsets.symmetric(
                                              vertical: 16.0, horizontal: 12.0),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '请输入验证码';
                                          }
                                          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                                            return '验证码为6位数字';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isVerificationCodeSent ? null : _sendVerificationCode,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                        ),
                                        child: Text(
                                          _isVerificationCodeSent ? '$_countdown秒' : '获取验证码',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (_isLogin && _loginMethod == 'email') ...[
                                // 保持原有邮箱验证码登录
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: '邮箱',
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: theme.iconTheme.color?.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 12.0),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入邮箱';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return '请输入有效的邮箱地址';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _verificationCodeController,
                                        decoration: InputDecoration(
                                          labelText: '验证码',
                                          prefixIcon: Icon(Icons.lock_outline,
                                              color: theme.iconTheme.color?.withOpacity(0.7)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          filled: true,
                                          fillColor:
                                              isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                          contentPadding: const EdgeInsets.symmetric(
                                              vertical: 16.0, horizontal: 12.0),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '请输入验证码';
                                          }
                                          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                                            return '验证码为6位数字';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isVerificationCodeSent ? null : _sendVerificationCode,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                        ),
                                        child: Text(
                                          _isVerificationCodeSent ? '$_countdown秒' : '获取验证码',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (!_isLogin) ...[
                                // 注册表单（根据快捷注册开关调整显示）
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: '用户名',
                                    prefixIcon: Icon(Icons.person_outline,
                                        color: theme.iconTheme.color?.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 12.0),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入用户名';
                                    }
                                    if (value.length < 3 || value.length > 20) {
                                      return '用户名长度必须在3-20个字符之间';
                                    }
                                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                                      return '用户名只能包含字母、数字和下划线';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: '密码',
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: theme.iconTheme.color?.withOpacity(0.7)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    filled: true,
                                    fillColor:
                                        isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16.0, horizontal: 12.0),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入密码';
                                    }
                                    if (value.length < 6) {
                                      return '密码长度至少为6位';
                                    }
                                    return null;
                                  },
                                ),

                                if (!quick) ...[
                                  const SizedBox(height: 16),
                                  // 邮箱输入（选填）
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: '邮箱（选填）',
                                      prefixIcon: Icon(Icons.email_outlined,
                                          color: theme.iconTheme.color?.withOpacity(0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 12.0),
                                      suffixIcon: _emailController.text.isNotEmpty
                                          ? TextButton(
                                              onPressed: _isVerificationCodeSent ? null : _sendVerificationCode,
                                              child: Text(
                                                _isVerificationCodeSent ? '$_countdown秒' : '发送验证码',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            )
                                          : null,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (value) {
                                      setState(() {}); // 刷新以显示/隐藏发送验证码按钮
                                    },
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(value)) {
                                          return '请输入有效的邮箱地址';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // 手机号输入（选填）
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      labelText: '手机号（选填）',
                                      prefixIcon: Icon(Icons.phone_outlined,
                                          color: theme.iconTheme.color?.withOpacity(0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 12.0),
                                      suffixIcon: _phoneController.text.isNotEmpty
                                          ? TextButton(
                                              onPressed: _isVerificationCodeSent ? null : _sendVerificationCode,
                                              child: Text(
                                                _isVerificationCodeSent ? '$_countdown秒' : '发送验证码',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            )
                                          : null,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    onChanged: (value) {
                                      setState(() {}); // 刷新以显示/隐藏发送验证码按钮
                                    },
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) {
                                          return '请输入正确的手机号';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  // 如果填写了邮箱或手机号，显示验证码输入框
                                  if (_emailController.text.isNotEmpty || _phoneController.text.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _verificationCodeController,
                                      decoration: InputDecoration(
                                        labelText: '验证码',
                                        prefixIcon: Icon(Icons.lock_outline,
                                            color: theme.iconTheme.color?.withOpacity(0.7)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        filled: true,
                                        fillColor:
                                            isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 16.0, horizontal: 12.0),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (_emailController.text.isNotEmpty || _phoneController.text.isNotEmpty) {
                                          if (value == null || value.isEmpty) {
                                            return '请输入验证码';
                                          }
                                          if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                                            return '验证码为6位数字';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // 图片验证码
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: _captchaController,
                                          decoration: InputDecoration(
                                            labelText: '图片验证码',
                                            prefixIcon: Icon(Icons.security,
                                                color: theme.iconTheme.color?.withOpacity(0.7)),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            filled: true,
                                            fillColor:
                                                isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                            contentPadding: const EdgeInsets.symmetric(
                                                vertical: 16.0, horizontal: 12.0),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return '请输入验证码';
                                            }
                                            if (value.length != 4) {
                                              return '验证码长度为4位';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 100,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme.dividerColor,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: InkWell(
                                          onTap: _loadCaptcha,
                                          child: _captchaImage != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    Uri.parse(_captchaImage!).data!.contentAsBytes(),
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],

                              const SizedBox(height: 24),

                              ElevatedButton(
                                onPressed: isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  backgroundColor: _hasNetworkConnection 
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                  foregroundColor: _hasNetworkConnection
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (!_hasNetworkConnection) ...[
                                            Icon(Icons.wifi_off, size: 20),
                                            SizedBox(width: 8),
                                          ],
                                          Text(
                                            !_hasNetworkConnection 
                                              ? '网络断开'
                                              : (_isLogin ? '登 录' : '注 册'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),

                              const SizedBox(height: 16),

                              TextButton(
                                onPressed: isLoading ? null : _toggleMode,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  _isLogin ? '还没有账户？立即注册' : '已有账户？前往登录',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 根据错误消息获取对应的图标
  IconData _getErrorIcon(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();
    
    if (lowerMessage.contains('网络') || lowerMessage.contains('连接')) {
      return Icons.wifi_off;
    } else if (lowerMessage.contains('密码') || lowerMessage.contains('用户名')) {
      return Icons.key_off;
    } else if (lowerMessage.contains('验证码')) {
      return Icons.security;
    } else if (lowerMessage.contains('服务器')) {
      return Icons.dns;
    } else if (lowerMessage.contains('超时')) {
      return Icons.timer_off;
    } else {
      return Icons.error_outline;
    }
  }

  /// 判断是否应该显示重试按钮
  bool _shouldShowRetryButton(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();
    
    // 对于以下类型的错误显示重试按钮
    return lowerMessage.contains('网络') || 
           lowerMessage.contains('连接') ||
           lowerMessage.contains('超时') ||
           lowerMessage.contains('服务器') ||
           lowerMessage.contains('请稍后重试');
  }

  /// 重试最后的操作
  void _retryLastAction() {
    // 根据当前状态重试相应操作
    if (_isLogin) {
      _submitForm();
    } else {
      // 注册模式下：如果是非快捷注册，可能需要重新加载验证码
      if (!(_registrationConfig?.quickRegistrationEnabled ?? true)) {
        _loadCaptcha();
      }
    }
  }
}
