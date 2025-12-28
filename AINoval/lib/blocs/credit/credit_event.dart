part of 'credit_bloc.dart';

/// 积分事件基类
abstract class CreditEvent extends Equatable {
  const CreditEvent();

  @override
  List<Object?> get props => [];
}

/// 加载用户积分事件
class LoadUserCredits extends CreditEvent {
  const LoadUserCredits();
}

/// 刷新用户积分事件
class RefreshUserCredits extends CreditEvent {
  const RefreshUserCredits();
} 

/// 清空用户积分状态事件（用于退出登录时重置为游客状态）
class ClearCredits extends CreditEvent {
  const ClearCredits();
}