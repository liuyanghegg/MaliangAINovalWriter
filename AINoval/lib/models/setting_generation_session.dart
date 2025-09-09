import 'dart:convert';
import 'setting_node.dart';
import '../utils/date_time_parser.dart';

/// 设定生成会话
class SettingGenerationSession {
  final String sessionId;
  final String userId;
  final String? novelId;
  final String initialPrompt;
  final String strategy;
  final String? modelConfigId;
  final SessionStatus status;
  final List<SettingNode> rootNodes;
  final Map<String, SettingNode> allNodes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final String? historyId; // 新增：关联的历史记录ID

  const SettingGenerationSession({
    required this.sessionId,
    required this.userId,
    this.novelId,
    required this.initialPrompt,
    required this.strategy,
    this.modelConfigId,
    required this.status,
    this.rootNodes = const [],
    this.allNodes = const {},
    required this.createdAt,
    this.updatedAt,
    this.errorMessage,
    this.metadata = const {},
    this.historyId, // 新增：历史记录ID参数
  });

  factory SettingGenerationSession.fromJson(Map<String, dynamic> json) {
    // 🔧 解析树形结构的rootNodes
    List<SettingNode> rootNodes = [];
    
    // 方式1：直接从rootNodes字段解析（新格式）
    if (json['rootNodes'] != null && json['rootNodes'] is List && (json['rootNodes'] as List).isNotEmpty) {
      rootNodes = (json['rootNodes'] as List)
          .map((node) => SettingNode.fromJson(node as Map<String, dynamic>))
          .toList();
    }
    // 方式2：从settings数组构建树形结构（兼容格式）
    else if (json['settings'] != null && json['settings'] is List) {
      rootNodes = _buildRootNodesFromSettings(json);
    }
    // 方式3：兼容旧格式的rootNodes解析
    else if (json['rootNodes'] != null && json['rootNodes'] is List) {
      rootNodes = (json['rootNodes'] as List)
          .map((node) => SettingNode.fromJson(node as Map<String, dynamic>))
          .toList();
    }
    
    // 兼容后端大写状态与CANCELLED状态
    SessionStatus parseStatus(dynamic raw) {
      if (raw == null) return SessionStatus.initializing;
      final statusStr = raw.toString().trim();
      final lower = statusStr.toLowerCase();
      switch (lower) {
        case 'initializing':
          return SessionStatus.initializing;
        case 'generating':
          return SessionStatus.generating;
        case 'completed':
          return SessionStatus.completed;
        case 'error':
          return SessionStatus.error;
        case 'saved':
          return SessionStatus.saved;
        case 'cancelled':
          // 前端未定义cancelled，兼容为错误状态显示
          return SessionStatus.error;
        default:
          // 兼容后端返回大写枚举，如 "COMPLETED"、"SAVED" 等
          if (statusStr == statusStr.toUpperCase()) {
            switch (statusStr) {
              case 'INITIALIZING':
                return SessionStatus.initializing;
              case 'GENERATING':
                return SessionStatus.generating;
              case 'COMPLETED':
                return SessionStatus.completed;
              case 'ERROR':
                return SessionStatus.error;
              case 'SAVED':
                return SessionStatus.saved;
              case 'CANCELLED':
                return SessionStatus.error;
            }
          }
          return SessionStatus.initializing;
      }
    }

    return SettingGenerationSession(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      novelId: json['novelId'] as String?,
      initialPrompt: json['initialPrompt'] as String,
      strategy: json['strategy'] as String,
      modelConfigId: json['modelConfigId'] as String?,
      status: parseStatus(json['status']),
      rootNodes: rootNodes,
      allNodes: json['allNodes'] != null
          ? Map<String, SettingNode>.fromEntries(
              (json['allNodes'] as Map<String, dynamic>).entries.map(
                (entry) => MapEntry(
                  entry.key,
                  SettingNode.fromJson(entry.value as Map<String, dynamic>),
                ),
              ),
            )
          : {},
      createdAt: parseBackendDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? parseBackendDateTime(json['updatedAt'])
          : null,
      errorMessage: json['errorMessage'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      historyId: json['historyId'] as String?, // 新增：从JSON解析historyId
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'userId': userId,
    'novelId': novelId,
    'initialPrompt': initialPrompt,
    'strategy': strategy,
    'modelConfigId': modelConfigId,
    'status': status.toString().split('.').last,
    'rootNodes': rootNodes.map((node) => node.toJson()).toList(),
    'allNodes': allNodes.map((key, value) => MapEntry(key, value.toJson())),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'metadata': metadata,
    'historyId': historyId, // 新增：序列化historyId
  };

  /// 从settings数组构建rootNodes树形结构
  static List<SettingNode> _buildRootNodesFromSettings(Map<String, dynamic> json) {
    List<SettingNode> rootNodes = [];
    
    try {
      final settings = json['settings'] as List?;
      final rootSettingIds = json['rootSettingIds'] as List?;
      final parentChildMap = json['parentChildMap'] as Map<String, dynamic>?;
      
      if (settings == null || settings.isEmpty) {
        return rootNodes;
      }
      
      // 将所有设定转换为SettingNode并建立索引
      Map<String, SettingNode> nodeMap = {};
      for (var settingData in settings) {
        if (settingData is Map<String, dynamic>) {
          var node = SettingNode.fromJson(settingData);
          nodeMap[node.id] = node;
        }
      }
      
      // 🔧 方式1：优先使用rootSettingIds
      if (rootSettingIds != null && rootSettingIds.isNotEmpty) {
        for (var rootId in rootSettingIds) {
          if (rootId is String && nodeMap.containsKey(rootId)) {
            var rootNode = nodeMap[rootId]!;
            // 构建这个根节点的完整子树
            var treeNode = _buildNodeTree(rootNode, nodeMap, parentChildMap);
            rootNodes.add(treeNode);
          }
        }
      } 
      // 🔧 方式2：查找parentId为null的节点
      else {
        for (var node in nodeMap.values) {
          if (node.parentId == null) {
            var treeNode = _buildNodeTree(node, nodeMap, parentChildMap);
            rootNodes.add(treeNode);
          }
        }
      }
      
    } catch (e) {
      print('解析settings构建树形结构失败: $e');
    }
    
    return rootNodes;
  }
  
  /// 递归构建节点树
  static SettingNode _buildNodeTree(
    SettingNode parentNode, 
    Map<String, SettingNode> nodeMap,
    Map<String, dynamic>? parentChildMap
  ) {
    List<SettingNode> children = [];
    
    // 🔧 方式1：从parentChildMap获取子节点ID列表
    if (parentChildMap != null && parentChildMap.containsKey(parentNode.id)) {
      var childIds = parentChildMap[parentNode.id] as List?;
      if (childIds != null) {
        for (var childId in childIds) {
          if (childId is String && nodeMap.containsKey(childId)) {
            var childNode = nodeMap[childId]!;
            var treeChild = _buildNodeTree(childNode, nodeMap, parentChildMap);
            children.add(treeChild);
          }
        }
      }
    }
    // 🔧 方式2：从所有节点中查找parentId指向当前节点的子节点
    else {
      for (var node in nodeMap.values) {
        if (node.parentId == parentNode.id) {
          var treeChild = _buildNodeTree(node, nodeMap, parentChildMap);
          children.add(treeChild);
        }
      }
    }
    
    // 返回包含子节点的节点副本
    return parentNode.copyWith(children: children);
  }

  SettingGenerationSession copyWith({
    String? sessionId,
    String? userId,
    String? novelId,
    String? initialPrompt,
    String? strategy,
    String? modelConfigId,
    SessionStatus? status,
    List<SettingNode>? rootNodes,
    Map<String, SettingNode>? allNodes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    String? historyId, // 新增：historyId参数
  }) {
    return SettingGenerationSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      novelId: novelId ?? this.novelId,
      initialPrompt: initialPrompt ?? this.initialPrompt,
      strategy: strategy ?? this.strategy,
      modelConfigId: modelConfigId ?? this.modelConfigId,
      status: status ?? this.status,
      rootNodes: rootNodes ?? this.rootNodes,
      allNodes: allNodes ?? this.allNodes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      historyId: historyId ?? this.historyId, // 新增：设置historyId
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// 会话状态
enum SessionStatus {
  /// 初始化
  initializing,
  /// 生成中
  generating,
  /// 已完成
  completed,
  /// 已错误
  error,
  /// 已保存
  saved,
}

/// 生成策略信息
class StrategyInfo {
  final String id;
  final String name;
  final String description;
  final bool enabled;
  final Map<String, dynamic> parameters;
  final int? expectedRootNodeCount;
  final int? maxDepth;

  const StrategyInfo({
    required this.id,
    required this.name,
    required this.description,
    this.enabled = true,
    this.parameters = const {},
    this.expectedRootNodeCount,
    this.maxDepth,
  });

  factory StrategyInfo.fromJson(Map<String, dynamic> json) {
    // 后端返回的格式：{name, description, expectedRootNodeCount, maxDepth}
    // 前端需要生成id字段
    String id;
    String name;
    String description;
    
    if (json.containsKey('id')) {
      // 如果已有id字段，直接使用
      id = json['id'] as String;
      name = json['name'] as String;
      description = json['description'] as String;
    } else {
      // 根据后端格式解析
      name = json['name'] as String;
      description = json['description'] as String;
      // 生成ID：将名称转换为小写并替换空格为横线
      id = name.toLowerCase().replaceAll(' ', '-').replaceAll('　', '-');
    }
    
    return StrategyInfo(
      id: id,
      name: name,
      description: description,
      enabled: json['enabled'] as bool? ?? true,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      expectedRootNodeCount: json['expectedRootNodeCount'] as int?,
      maxDepth: json['maxDepth'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'enabled': enabled,
    'parameters': parameters,
    if (expectedRootNodeCount != null) 'expectedRootNodeCount': expectedRootNodeCount,
    if (maxDepth != null) 'maxDepth': maxDepth,
  };
}
