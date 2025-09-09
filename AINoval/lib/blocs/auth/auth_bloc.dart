import 'dart:async';

import 'package:ainoval/services/auth_service.dart' as auth_service;
import 'package:ainoval/utils/logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 认证事件
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

// 初始化认证事件
class AuthInitialize extends AuthEvent {}

// 登录事件
class AuthLogin extends AuthEvent {
  
  const AuthLogin({required this.username, required this.password});
  final String username;
  final String password;
  
  @override
  List<Object?> get props => [username, password];
}

// 注册事件
class AuthRegister extends AuthEvent {
  
  const AuthRegister({
    required this.username, 
    required this.password, 
    this.email,
    this.phone,
    this.displayName,
    this.captchaId,
    this.captchaCode,
    this.emailVerificationCode,
    this.phoneVerificationCode,
  });
  final String username;
  final String password;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? captchaId;
  final String? captchaCode;
  final String? emailVerificationCode;
  final String? phoneVerificationCode;
  
  @override
  List<Object?> get props => [username, password, email, phone, displayName, captchaId, captchaCode, emailVerificationCode, phoneVerificationCode];
}

// 手机号登录事件
class PhoneLogin extends AuthEvent {
  const PhoneLogin({
    required this.phone,
    required this.verificationCode,
  });
  final String phone;
  final String verificationCode;
  
  @override
  List<Object?> get props => [phone, verificationCode];
}

// 邮箱登录事件
class EmailLogin extends AuthEvent {
  const EmailLogin({
    required this.email,
    required this.verificationCode,
  });
  final String email;
  final String verificationCode;
  
  @override
  List<Object?> get props => [email, verificationCode];
}

// 发送验证码事件（登录时使用）
class SendVerificationCode extends AuthEvent {
  const SendVerificationCode({
    required this.type,
    required this.target,
    required this.purpose,
  });
  final String type; // phone or email
  final String target; // phone number or email address
  final String purpose; // login or register
  
  @override
  List<Object?> get props => [type, target, purpose];
}

// 发送验证码事件（注册时使用，需要图片验证码）
class SendVerificationCodeWithCaptcha extends AuthEvent {
  const SendVerificationCodeWithCaptcha({
    required this.type,
    required this.target,
    required this.purpose,
    required this.captchaId,
    required this.captchaCode,
  });
  final String type; // phone or email
  final String target; // phone number or email address
  final String purpose; // register
  final String captchaId; // captcha id
  final String captchaCode; // captcha code
  
  @override
  List<Object?> get props => [type, target, purpose, captchaId, captchaCode];
}

// 加载图片验证码事件
class LoadCaptcha extends AuthEvent {}

// 登出事件
class AuthLogout extends AuthEvent {}

// AuthService状态变化事件
class AuthServiceStateChanged extends AuthEvent {
  const AuthServiceStateChanged(this.authState);
  final auth_service.AuthState authState;
  
  @override
  List<Object?> get props => [authState];
}

// 认证状态
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

// 初始状态
class AuthInitial extends AuthState {
  const AuthInitial();
  
  @override
  List<Object?> get props => [];
}

// 认证中状态
class AuthLoading extends AuthState {
  const AuthLoading();
  
  @override
  List<Object?> get props => [];
}

// 已认证状态
class AuthAuthenticated extends AuthState {
  
  const AuthAuthenticated({required this.userId, required this.username});
  final String userId;
  final String username;
  
  @override
  List<Object?> get props => [userId, username];
}

// 未认证状态
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
  
  @override
  List<Object?> get props => [];
}

// 认证错误状态
class AuthError extends AuthState {
  
  const AuthError({required this.message});
  final String message;
  
  @override
  List<Object?> get props => [message];
}

// 图片验证码加载完成状态
class CaptchaLoaded extends AuthState {
  const CaptchaLoaded({
    required this.captchaId,
    required this.captchaImage,
  });
  final String captchaId;
  final String captchaImage;
  
  @override
  List<Object?> get props => [captchaId, captchaImage];
}

// 验证码发送成功状态
class VerificationCodeSent extends AuthState {
  const VerificationCodeSent({this.message = '验证码已发送'});
  final String message;
  
  @override
  List<Object?> get props => [message];
}

// 认证Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  
  AuthBloc({required auth_service.AuthService authService}) 
      : _authService = authService,
        super(const AuthInitial()) {
    on<AuthInitialize>(_onInitialize);
    on<AuthLogin>(_onLogin);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<PhoneLogin>(_onPhoneLogin);
    on<EmailLogin>(_onEmailLogin);
    on<SendVerificationCode>(_onSendVerificationCode);
    on<SendVerificationCodeWithCaptcha>(_onSendVerificationCodeWithCaptcha);
    on<LoadCaptcha>(_onLoadCaptcha);
    on<AuthServiceStateChanged>(_onAuthServiceStateChanged);
    
    // 监听认证服务的状态变化
    _authStateSubscription = _authService.authStateStream.listen((authState) {
      add(AuthServiceStateChanged(authState));
    });
  }
  final auth_service.AuthService _authService;
  StreamSubscription? _authStateSubscription;
  
  Future<void> _onInitialize(AuthInitialize event, Emitter<AuthState> emit) async {
    final currentState = _authService.currentState;
    
    if (currentState.isAuthenticated) {
      emit(AuthAuthenticated(
        userId: currentState.userId,
        username: currentState.username,
      ));
    } else {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    try {
      final result = await _authService.login(event.username, event.password);
      
      if (result.isAuthenticated) {
        emit(AuthAuthenticated(
          userId: result.userId,
          username: result.username,
        ));
      } else {
        emit(AuthError(message: result.error ?? '登录失败'));
      }
    } catch (e) {
      // 优先使用后端返回的错误信息
      emit(AuthError(message: e.toString().replaceFirst('AuthException: ', '')));
    }
  }
  
  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    try {
      final bool needVerification = (event.email != null && event.email!.isNotEmpty) ||
          (event.phone != null && event.phone!.isNotEmpty) ||
          (event.captchaId != null && event.captchaId!.isNotEmpty) ||
          (event.captchaCode != null && event.captchaCode!.isNotEmpty) ||
          (event.emailVerificationCode != null && event.emailVerificationCode!.isNotEmpty) ||
          (event.phoneVerificationCode != null && event.phoneVerificationCode!.isNotEmpty);

      final auth_service.AuthState result = needVerification
          ? await _authService.registerWithVerification(
              username: event.username,
              password: event.password,
              email: event.email,
              phone: event.phone,
              displayName: event.displayName,
              captchaId: event.captchaId,
              captchaCode: event.captchaCode,
              emailVerificationCode: event.emailVerificationCode,
              phoneVerificationCode: event.phoneVerificationCode,
            )
          : await _authService.registerQuick(
              username: event.username,
              password: event.password,
              displayName: event.displayName,
            );
      
      if (result.isAuthenticated) {
        emit(AuthAuthenticated(
          userId: result.userId,
          username: result.username,
        ));
      } else {
        emit(AuthError(message: result.error ?? '注册失败'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('AuthException: ', '')));
    }
  }
  
  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    AppLogger.i('AuthBloc', '开始执行退出登录');
    emit(const AuthLoading());
    
    try {
      // 调用AuthService清除认证状态，但不等待完成
      _authService.logout().catchError((e) {
        AppLogger.w('AuthBloc', 'AuthService.logout()执行出错，但不影响BLoC状态', e);
      });
      
      // 立即发出未认证状态，确保UI快速响应
      AppLogger.i('AuthBloc', '发出AuthUnauthenticated状态');
      const unauthenticatedState = AuthUnauthenticated();
      AppLogger.i('AuthBloc', '准备emit状态: ${unauthenticatedState.runtimeType} - ${unauthenticatedState.hashCode}');
      emit(unauthenticatedState);
      AppLogger.i('AuthBloc', '已emit AuthUnauthenticated状态，当前BLoC状态: ${state.runtimeType}');
    } catch (e) {
      // 即使出现任何错误，都要确保用户退出到登录页面
      AppLogger.w('AuthBloc', '退出登录过程中出现错误，强制设为未认证状态', e);
      emit(const AuthUnauthenticated());
    }
  }
  
  Future<void> _onPhoneLogin(PhoneLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    try {
      final result = await _authService.loginWithPhone(
        phone: event.phone,
        verificationCode: event.verificationCode,
      );
      
      if (result.isAuthenticated) {
        emit(AuthAuthenticated(
          userId: result.userId,
          username: result.username,
        ));
      } else {
        emit(AuthError(message: result.error ?? '登录失败'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('AuthException: ', '')));
    }
  }
  
  Future<void> _onEmailLogin(EmailLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    try {
      final result = await _authService.loginWithEmail(
        email: event.email,
        verificationCode: event.verificationCode,
      );
      
      if (result.isAuthenticated) {
        emit(AuthAuthenticated(
          userId: result.userId,
          username: result.username,
        ));
      } else {
        emit(AuthError(message: result.error ?? '登录失败'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceFirst('AuthException: ', '')));
    }
  }
  
  Future<void> _onSendVerificationCode(SendVerificationCode event, Emitter<AuthState> emit) async {
    try {
      final success = await _authService.sendVerificationCode(
        type: event.type,
        target: event.target,
        purpose: event.purpose,
      );
      
      if (success) {
        emit(VerificationCodeSent());
        // 不需要调用AuthInitialize，避免重置认证状态
      } else {
        emit(const AuthError(message: '验证码发送失败，请稍后重试'));
      }
    } catch (e) {
      emit(AuthError(message: _formatUserFriendlyError(e)));
    }
  }

  Future<void> _onSendVerificationCodeWithCaptcha(SendVerificationCodeWithCaptcha event, Emitter<AuthState> emit) async {
    try {
      // 先验证图片验证码是否填写
      if (event.captchaCode.isEmpty) {
        emit(const AuthError(message: '请输入图片验证码'));
        return;
      }
      
      final success = await _authService.sendVerificationCodeWithCaptcha(
        type: event.type,
        target: event.target,
        purpose: event.purpose,
        captchaId: event.captchaId,
        captchaCode: event.captchaCode,
      );
      
      if (success) {
        emit(VerificationCodeSent(message: '验证码已发送，请查收'));
        // 验证码发送成功后，保持当前的图片验证码
        // 用户注册时将使用相同的图片验证码ID和内容
        await Future.delayed(const Duration(milliseconds: 100));
        // 返回到图片验证码加载状态，但不重新加载（保持一致性）
        if (state is CaptchaLoaded) {
          final currentState = state as CaptchaLoaded;
          emit(CaptchaLoaded(
            captchaId: currentState.captchaId,
            captchaImage: currentState.captchaImage,
          ));
        }
      } else {
        emit(const AuthError(message: '验证码发送失败，请稍后重试'));
      }
    } catch (e) {
      final errorMessage = e.toString().contains('图片验证码') 
          ? e.toString().replaceFirst('Exception: ', '') 
          : '验证码发送失败：${_formatUserFriendlyError(e)}';
      emit(AuthError(message: errorMessage));
      // 验证失败时重新加载图片验证码
      add(LoadCaptcha());
    }
  }
  
  Future<void> _onLoadCaptcha(LoadCaptcha event, Emitter<AuthState> emit) async {
    try {
      final captchaData = await _authService.loadCaptcha();
      
      if (captchaData != null) {
        emit(CaptchaLoaded(
          captchaId: captchaData['captchaId'] ?? '',
          captchaImage: captchaData['captchaImage'] ?? '',
        ));
      } else {
        emit(const AuthError(message: '加载验证码失败'));
      }
    } catch (e) {
      emit(AuthError(message: _formatUserFriendlyError(e)));
    }
  }
  
  Future<void> _onAuthServiceStateChanged(AuthServiceStateChanged event, Emitter<AuthState> emit) async {
    final authState = event.authState;
    
    if (authState.isAuthenticated) {
      emit(AuthAuthenticated(
        userId: authState.userId,
        username: authState.username,
      ));
    } else if (authState.error != null) {
      emit(AuthError(message: authState.error!));
    } else {
      emit(AuthUnauthenticated());
    }
  }
  
  /// 将技术性错误转换为用户友好的错误消息
  String _formatUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // 网络相关错误
    if (errorString.contains('connection') || errorString.contains('network') || errorString.contains('timeout')) {
      return '网络连接失败，请检查您的网络连接后重试';
    }
    
    // 认证相关错误
    if (errorString.contains('unauthorized') || errorString.contains('401') || errorString.contains('authentication')) {
      return '用户名或密码错误，请重新输入';
    }
    
    // 服务器错误
    if (errorString.contains('500') || errorString.contains('server') || errorString.contains('internal')) {
      return '服务器暂时无法访问，请稍后重试';
    }
    
    // 验证码相关错误
    if (errorString.contains('captcha') || errorString.contains('verification')) {
      return '验证码错误或已过期，请重新输入';
    }
    
    // 用户不存在
    if (errorString.contains('user not found') || errorString.contains('not found')) {
      return '用户不存在，请检查用户名或先注册账号';
    }
    
    // 密码错误
    if (errorString.contains('password') && errorString.contains('wrong')) {
      return '密码错误，请重新输入正确的密码';
    }
    
    // 账号被禁用
    if (errorString.contains('disabled') || errorString.contains('banned')) {
      return '账号已被禁用，请联系管理员';
    }
    
    // 格式错误
    if (errorString.contains('format') || errorString.contains('invalid')) {
      return '输入格式不正确，请检查后重新输入';
    }
    
    // 如果是AuthException，尝试提取更友好的消息
    if (error.runtimeType.toString().contains('AuthException')) {
      final message = error.toString();
      if (message.contains('AuthException:')) {
        return message.replaceAll('AuthException:', '').trim();
      }
    }
    
    // 默认友好错误消息
    return '登录失败，请稍后重试或联系客服';
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
} 