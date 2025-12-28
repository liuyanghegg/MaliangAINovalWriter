part of 'public_models_bloc.dart';

/// 公共模型事件基类
abstract class PublicModelsEvent extends Equatable {
  const PublicModelsEvent();

  @override
  List<Object?> get props => [];
}

/// 加载公共模型列表事件
class LoadPublicModels extends PublicModelsEvent {
  const LoadPublicModels();
}

/// 刷新公共模型列表事件
class RefreshPublicModels extends PublicModelsEvent {
  const RefreshPublicModels();
} 