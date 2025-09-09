import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/api_service/repositories/impl/admin_repository_impl.dart';
import '../../models/admin/admin_models.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepositoryImpl adminRepository;

  AdminBloc(this.adminRepository) : super(AdminInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<LoadUsers>(_onLoadUsers);
    on<LoadRoles>(_onLoadRoles);
    on<LoadModelConfigs>(_onLoadModelConfigs);
    on<LoadSystemConfigs>(_onLoadSystemConfigs);
    on<UpdateUserStatus>(_onUpdateUserStatus);
    on<CreateRole>(_onCreateRole);
    on<UpdateRole>(_onUpdateRole);
    on<UpdateModelConfig>(_onUpdateModelConfig);
    on<UpdateSystemConfig>(_onUpdateSystemConfig);
    on<AddCreditsToUser>(_onAddCreditsToUser);
    on<DeductCreditsFromUser>(_onDeductCreditsFromUser);
    on<UpdateUserInfo>(_onUpdateUserInfo);
    on<AssignRoleToUser>(_onAssignRoleToUser);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final stats = await adminRepository.getDashboardStats();
      emit(DashboardStatsLoaded(stats));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final users = await adminRepository.getUsers(
        page: event.page,
        size: event.size,
        search: event.search,
      );
      emit(UsersLoaded(users));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadRoles(
    LoadRoles event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final roles = await adminRepository.getRoles();
      emit(RolesLoaded(roles));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadModelConfigs(
    LoadModelConfigs event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final configs = await adminRepository.getModelConfigs();
      emit(ModelConfigsLoaded(configs));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadSystemConfigs(
    LoadSystemConfigs event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final configs = await adminRepository.getSystemConfigs();
      emit(SystemConfigsLoaded(configs));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateUserStatus(
    UpdateUserStatus event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.updateUserStatus(event.userId, event.status);
      // 重新加载用户列表
      add(LoadUsers());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateRole(
    CreateRole event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.createRole(event.role);
      // 重新加载角色列表
      add(LoadRoles());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateRole(
    UpdateRole event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.updateRole(event.roleId, event.role);
      // 重新加载角色列表
      add(LoadRoles());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateModelConfig(
    UpdateModelConfig event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.updateModelConfig(event.configId, event.config);
      // 重新加载模型配置列表
      add(LoadModelConfigs());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateSystemConfig(
    UpdateSystemConfig event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.updateSystemConfig(event.configKey, event.value);
      // 重新加载系统配置列表
      add(LoadSystemConfigs());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAddCreditsToUser(
    AddCreditsToUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.addCreditsToUser(event.userId, event.amount, event.reason);
      // 重新加载用户列表
      add(LoadUsers());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeductCreditsFromUser(
    DeductCreditsFromUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.deductCreditsFromUser(event.userId, event.amount, event.reason);
      // 重新加载用户列表
      add(LoadUsers());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateUserInfo(
    UpdateUserInfo event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.updateUserInfo(
        event.userId, 
        email: event.email,
        displayName: event.displayName,
        accountStatus: event.accountStatus,
      );
      // 重新加载用户列表
      add(LoadUsers());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAssignRoleToUser(
    AssignRoleToUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await adminRepository.assignRoleToUser(event.userId, event.roleId);
      // 重新加载用户列表
      add(LoadUsers());
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}