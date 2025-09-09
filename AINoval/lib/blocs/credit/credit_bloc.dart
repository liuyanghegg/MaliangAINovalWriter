import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/user_credit.dart';
import '../../services/api_service/repositories/credit_repository.dart';
import '../../utils/logger.dart';

part 'credit_event.dart';
part 'credit_state.dart';

/// 用户积分BLoC
/// 负责管理用户积分状态和数据获取
class CreditBloc extends Bloc<CreditEvent, CreditState> {
  final CreditRepository _repository;
  static const String _tag = 'CreditBloc';

  CreditBloc({required CreditRepository repository})
      : _repository = repository,
        super(const CreditInitial()) {
    on<LoadUserCredits>(_onLoadUserCredits);
    on<RefreshUserCredits>(_onRefreshUserCredits);
    on<ClearCredits>(_onClearCredits);
  }

  /// 处理加载用户积分事件
  Future<void> _onLoadUserCredits(
    LoadUserCredits event,
    Emitter<CreditState> emit,
  ) async {
    emit(const CreditLoading());
    await _loadCredits(emit);
  }

  /// 处理刷新用户积分事件
  Future<void> _onRefreshUserCredits(
    RefreshUserCredits event,
    Emitter<CreditState> emit,
  ) async {
    // 刷新不显示loading状态，保持当前显示
    await _loadCredits(emit);
  }

  /// 处理清空用户积分事件
  Future<void> _onClearCredits(
    ClearCredits event,
    Emitter<CreditState> emit,
  ) async {
    AppLogger.i(_tag, '清空用户积分状态，重置为初始状态');
    emit(const CreditInitial());
  }

  /// 加载积分的公共方法
  Future<void> _loadCredits(Emitter<CreditState> emit) async {
    try {
      AppLogger.i(_tag, '开始加载用户积分');
      final userCredit = await _repository.getUserCredits();
      
      AppLogger.i(_tag, '用户积分加载成功: ${userCredit.credits}');
      emit(CreditLoaded(userCredit: userCredit));
    } catch (e, stackTrace) {
      AppLogger.e(_tag, '加载用户积分失败', e, stackTrace);
      emit(CreditError(message: '加载用户积分失败: ${e.toString()}'));
    }
  }
} 