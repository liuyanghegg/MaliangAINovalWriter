import 'package:equatable/equatable.dart';

import 'public_model_config.dart';
import 'user_ai_model_config_model.dart';

/// 统一的AI模型接口
/// 可以同时表示用户私有模型和公共模型
abstract class UnifiedAIModel extends Equatable {
  /// 模型ID
  String get id;
  
  /// 提供商
  String get provider;
  
  /// 模型名称/标识
  String get modelId;
  
  /// 显示名称
  String get displayName;
  
  /// 是否为公共模型
  bool get isPublic;
  
  /// 是否已验证
  bool get isValidated;
  
  /// 积分倍率显示文本（仅公共模型有效）
  String get creditMultiplierDisplay;
  
  /// 获取模型标签（如 [系统]、[积分x1.2] 等）
  List<String> get modelTags;
}

/// 用户私有模型包装器
class PrivateAIModel extends UnifiedAIModel {
  final UserAIModelConfigModel _model;
  
  PrivateAIModel(this._model);
  
  @override
  String get id => _model.id;
  
  @override
  String get provider => _model.provider;
  
  @override
  String get modelId => _model.modelName;
  
  @override
  String get displayName => _model.name;
  
  @override
  bool get isPublic => false;
  
  @override
  bool get isValidated => _model.isValidated;
  
  @override
  String get creditMultiplierDisplay => '';
  
  @override
  List<String> get modelTags => ['私有'];
  
  /// 获取原始的用户模型配置
  UserAIModelConfigModel get userConfig => _model;
  
  @override
  List<Object?> get props => [_model];
}

/// 公共模型包装器
class PublicAIModel extends UnifiedAIModel {
  final PublicModel _model;
  
  PublicAIModel(this._model);
  
  @override
  String get id => _model.id;
  
  @override
  String get provider => _model.provider;
  
  @override
  String get modelId => _model.modelId;
  
  @override
  String get displayName => _model.displayName;
  
  @override
  bool get isPublic => true;
  
  @override
  bool get isValidated => true; // 公共模型默认已验证
  
  @override
  String get creditMultiplierDisplay => _model.creditMultiplierDisplay;
  
  @override
  List<String> get modelTags {
    final tags = <String>['系统'];
    if (_model.creditMultiplierDisplay.isNotEmpty) {
      tags.add(_model.creditMultiplierDisplay);
    }
    if (_model.recommended == true) {
      tags.add('推荐');
    }
    if (_model.tags != null) {
      tags.addAll(_model.tags!);
    }
    return tags;
  }
  
  /// 获取原始的公共模型配置
  PublicModel get publicConfig => _model;
  
  @override
  List<Object?> get props => [_model];
} 