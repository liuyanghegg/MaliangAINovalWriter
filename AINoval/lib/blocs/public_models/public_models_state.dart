part of 'public_models_bloc.dart';

/// 公共模型状态基类
abstract class PublicModelsState extends Equatable {
  const PublicModelsState();

  @override
  List<Object?> get props => [];
}

/// 公共模型初始状态
class PublicModelsInitial extends PublicModelsState {
  const PublicModelsInitial();
}

/// 公共模型加载中状态
class PublicModelsLoading extends PublicModelsState {
  const PublicModelsLoading();
}

/// 公共模型加载成功状态
class PublicModelsLoaded extends PublicModelsState {
  final List<PublicModel> models;

  const PublicModelsLoaded({required this.models});

  @override
  List<Object?> get props => [models];

  /// 创建副本，用于更新状态
  PublicModelsLoaded copyWith({
    List<PublicModel>? models,
  }) {
    return PublicModelsLoaded(
      models: models ?? this.models,
    );
  }
}

/// 公共模型加载失败状态
class PublicModelsError extends PublicModelsState {
  final String message;

  const PublicModelsError({required this.message});

  @override
  List<Object?> get props => [message];
} 