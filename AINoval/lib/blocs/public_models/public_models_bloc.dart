import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/public_model_config.dart';
import '../../services/api_service/repositories/public_model_repository.dart';
import '../../utils/logger.dart';

part 'public_models_event.dart';
part 'public_models_state.dart';

/// 公共模型BLoC
/// 负责管理公共模型池的状态和数据获取
class PublicModelsBloc extends Bloc<PublicModelsEvent, PublicModelsState> {
  final PublicModelRepository _repository;
  static const String _tag = 'PublicModelsBloc';

  PublicModelsBloc({required PublicModelRepository repository})
      : _repository = repository,
        super(const PublicModelsInitial()) {
    on<LoadPublicModels>(_onLoadPublicModels);
    on<RefreshPublicModels>(_onRefreshPublicModels);
  }

  /// 处理加载公共模型列表事件
  Future<void> _onLoadPublicModels(
    LoadPublicModels event,
    Emitter<PublicModelsState> emit,
  ) async {
    emit(const PublicModelsLoading());
    await _loadModels(emit);
  }

  /// 处理刷新公共模型列表事件
  Future<void> _onRefreshPublicModels(
    RefreshPublicModels event,
    Emitter<PublicModelsState> emit,
  ) async {
    // 刷新不显示loading状态，保持当前显示
    await _loadModels(emit);
  }

  /// 加载模型列表的公共方法
  Future<void> _loadModels(Emitter<PublicModelsState> emit) async {
    try {
      AppLogger.i(_tag, '开始加载公共模型列表');
      final models = await _repository.getPublicModels();
      
      // 按优先级排序，优先级高的在前
      models.sort((a, b) {
        final aPriority = a.priority ?? 0;
        final bPriority = b.priority ?? 0;
        return bPriority.compareTo(aPriority);
      });
      
      AppLogger.i(_tag, '公共模型列表加载成功: 共${models.length}个模型');
      emit(PublicModelsLoaded(models: models));
    } catch (e, stackTrace) {
      AppLogger.e(_tag, '加载公共模型列表失败', e, stackTrace);
      emit(PublicModelsError(message: '加载公共模型列表失败: ${e.toString()}'));
    }
  }
} 