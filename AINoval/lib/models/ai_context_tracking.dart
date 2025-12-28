/// AI上下文追踪选项枚举
enum AIContextTracking {
  /// 总是包含在AI上下文中
  /// 此条目被标记为全局，其信息总是呈现给AI
  always('always', '总是包含', '此条目被标记为全局，其信息总是呈现给AI'),
  
  /// 检测到时包含（默认）
  /// 当在文本/选择/聊天消息中检测到此条目时，将其添加到上下文中
  detected('detected', '检测到时包含', '当在文本/选择/聊天消息中检测到此条目时，将其添加到上下文中'),
  
  /// 检测到时不包含
  /// 即使检测到也不要将此条目添加到上下文中，但在被引用或手动添加为场景上下文时仍可拉入
  dontInclude('dont_include', '检测到时不包含', '即使检测到也不要将此条目添加到上下文中，但在被引用或手动添加为场景上下文时仍可拉入'),
  
  /// 从不包含
  /// 此条目永远不会显示给AI，对于私人笔记或无关信息很有用
  never('never', '从不包含', '此条目永远不会显示给AI，对于私人笔记或无关信息很有用');

  const AIContextTracking(this.value, this.displayName, this.description);
  
  final String value;
  final String displayName;
  final String description;
  
  /// 根据值获取枚举
  static AIContextTracking fromValue(String? value) {
    if (value == null) return detected; // 默认值
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => detected,
    );
  }
  
  /// 获取所有追踪选项的显示名称
  static List<String> get allDisplayNames {
    return values.map((type) => type.displayName).toList();
  }
  
  /// 是否应该包含在AI上下文中
  bool shouldIncludeInContext({
    bool isDetected = false, 
    bool isManuallyAdded = false,
    bool isReferenced = false,
  }) {
    switch (this) {
      case always:
        return true;
      case detected:
        return isDetected || isManuallyAdded || isReferenced;
      case dontInclude:
        return isManuallyAdded || isReferenced;
      case never:
        return false;
    }
  }
}

/// 设定引用修改选项枚举
enum SettingReferenceUpdate {
  /// 修改此设定时，自动更新所有引用此设定的地方
  update('update', '自动更新引用', '修改此设定时，自动更新所有引用此设定的地方'),
  
  /// 修改此设定时，询问是否更新引用
  ask('ask', '询问是否更新', '修改此设定时，询问是否更新引用'),
  
  /// 修改此设定时，不更新引用
  noUpdate('no_update', '不更新引用', '修改此设定时，不更新引用');

  const SettingReferenceUpdate(this.value, this.displayName, this.description);
  
  final String value;
  final String displayName;
  final String description;
  
  /// 根据值获取枚举
  static SettingReferenceUpdate fromValue(String? value) {
    if (value == null) return ask; // 默认值
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => ask,
    );
  }
}

/// 名称/别名追踪选项枚举
enum NameAliasTracking {
  /// 通过名称/别名追踪此条目
  track('track', '通过名称/别名追踪', '通过名称/别名追踪此条目'),
  
  /// 不追踪此条目
  noTrack('no_track', '不追踪', '不追踪此条目');

  const NameAliasTracking(this.value, this.displayName, this.description);
  
  final String value;
  final String displayName;
  final String description;
  
  /// 根据值获取枚举
  static NameAliasTracking fromValue(String? value) {
    if (value == null) return track; // 默认值
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => track,
    );
  }
}