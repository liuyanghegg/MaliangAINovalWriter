import 'dart:convert';
import 'setting_type.dart';

/// 设定节点
class SettingNode {
  final String id;
  final String? parentId;
  final String name;
  final SettingType type;
  final String description;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> strategyMetadata;
  final GenerationStatus generationStatus;
  final String? errorMessage;
  final String? generationPrompt;
  final List<SettingNode>? children;

  const SettingNode({
    required this.id,
    this.parentId,
    required this.name,
    required this.type,
    required this.description,
    this.attributes = const {},
    this.strategyMetadata = const {},
    this.generationStatus = GenerationStatus.pending,
    this.errorMessage,
    this.generationPrompt,
    this.children,
  });

  factory SettingNode.fromJson(Map<String, dynamic> json) {
    return SettingNode(
      id: json['id'] as String,
      parentId: json['parentId'] as String?,
      name: json['name'] as String,
      type: SettingType.fromJson(json['type']),
      description: json['description'] as String,
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
      strategyMetadata: Map<String, dynamic>.from(json['strategyMetadata'] ?? {}),
      generationStatus: GenerationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['generationStatus'],
        orElse: () => GenerationStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
      generationPrompt: json['generationPrompt'] as String?,
      children: json['children'] != null 
        ? (json['children'] as List)
            .map((child) => SettingNode.fromJson(child as Map<String, dynamic>))
            .toList()
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'type': type.toJson(),
      'description': description,
      'attributes': attributes,
      'strategyMetadata': strategyMetadata,
      'generationStatus': generationStatus.toString().split('.').last,
      'errorMessage': errorMessage,
      'generationPrompt': generationPrompt,
      'children': children?.map((child) => child.toJson()).toList(),
    };
  }

  SettingNode copyWith({
    String? id,
    String? parentId,
    String? name,
    SettingType? type,
    String? description,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? strategyMetadata,
    GenerationStatus? generationStatus,
    String? errorMessage,
    String? generationPrompt,
    List<SettingNode>? children,
  }) {
    return SettingNode(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      attributes: attributes ?? this.attributes,
      strategyMetadata: strategyMetadata ?? this.strategyMetadata,
      generationStatus: generationStatus ?? this.generationStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      generationPrompt: generationPrompt ?? this.generationPrompt,
      children: children ?? this.children,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 生成状态枚举
enum GenerationStatus {
  /// 待生成
  pending,
  /// 生成中
  generating,
  /// 已完成
  completed,
  /// 生成失败
  failed,
  /// 已修改
  modified,
}
