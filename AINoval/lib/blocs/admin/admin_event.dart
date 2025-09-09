part of 'admin_bloc.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends AdminEvent {}

class LoadUsers extends AdminEvent {
  final int page;
  final int size;
  final String? search;

  const LoadUsers({
    this.page = 0,
    this.size = 20,
    this.search,
  });

  @override
  List<Object?> get props => [page, size, search];
}

class LoadRoles extends AdminEvent {}

class LoadModelConfigs extends AdminEvent {}

class LoadSystemConfigs extends AdminEvent {}

class UpdateUserStatus extends AdminEvent {
  final String userId;
  final String status;

  const UpdateUserStatus({
    required this.userId,
    required this.status,
  });

  @override
  List<Object> get props => [userId, status];
}

class CreateRole extends AdminEvent {
  final AdminRole role;

  const CreateRole(this.role);

  @override
  List<Object> get props => [role];
}

class UpdateRole extends AdminEvent {
  final String roleId;
  final AdminRole role;

  const UpdateRole({
    required this.roleId,
    required this.role,
  });

  @override
  List<Object> get props => [roleId, role];
}

class UpdateModelConfig extends AdminEvent {
  final String configId;
  final AdminModelConfig config;

  const UpdateModelConfig({
    required this.configId,
    required this.config,
  });

  @override
  List<Object> get props => [configId, config];
}

class UpdateSystemConfig extends AdminEvent {
  final String configKey;
  final String value;

  const UpdateSystemConfig({
    required this.configKey,
    required this.value,
  });

  @override
  List<Object> get props => [configKey, value];
}

// 添加积分管理相关事件
class AddCreditsToUser extends AdminEvent {
  final String userId;
  final int amount;
  final String reason;

  const AddCreditsToUser({
    required this.userId,
    required this.amount,
    required this.reason,
  });

  @override
  List<Object> get props => [userId, amount, reason];
}

class DeductCreditsFromUser extends AdminEvent {
  final String userId;
  final int amount;
  final String reason;

  const DeductCreditsFromUser({
    required this.userId,
    required this.amount,
    required this.reason,
  });

  @override
  List<Object> get props => [userId, amount, reason];
}

class UpdateUserInfo extends AdminEvent {
  final String userId;
  final String? email;
  final String? displayName;
  final String? accountStatus;

  const UpdateUserInfo({
    required this.userId,
    this.email,
    this.displayName,
    this.accountStatus,
  });

  @override
  List<Object?> get props => [userId, email, displayName, accountStatus];
}

class AssignRoleToUser extends AdminEvent {
  final String userId;
  final String roleId;

  const AssignRoleToUser({
    required this.userId,
    required this.roleId,
  });

  @override
  List<Object> get props => [userId, roleId];
}