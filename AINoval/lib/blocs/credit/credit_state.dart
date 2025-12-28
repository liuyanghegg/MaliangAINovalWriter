part of 'credit_bloc.dart';

/// 积分状态基类
abstract class CreditState extends Equatable {
  const CreditState();

  @override
  List<Object?> get props => [];
}

/// 积分初始状态
class CreditInitial extends CreditState {
  const CreditInitial();
}

/// 积分加载中状态
class CreditLoading extends CreditState {
  const CreditLoading();
}

/// 积分加载成功状态
class CreditLoaded extends CreditState {
  final UserCredit userCredit;

  const CreditLoaded({required this.userCredit});

  @override
  List<Object?> get props => [userCredit];

  /// 创建副本
  CreditLoaded copyWith({
    UserCredit? userCredit,
  }) {
    return CreditLoaded(
      userCredit: userCredit ?? this.userCredit,
    );
  }
}

/// 积分加载失败状态
class CreditError extends CreditState {
  final String message;

  const CreditError({required this.message});

  @override
  List<Object?> get props => [message];
} 