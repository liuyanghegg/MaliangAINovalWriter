/// 设定关系类型枚举
/// 保留现有的关系系统，但重点突出父子关系
enum SettingRelationshipType {
  // 核心：父子关系（最重要）
  parent('parent', '父设定'),
  child('child', '子设定'),
  
  // 常用关系
  friend('friend', '朋友'),
  enemy('enemy', '敌人'),
  ally('ally', '盟友'),
  rival('rival', '竞争对手'),
  
  // 归属关系
  owns('owns', '拥有'),
  ownedBy('ownedBy', '被拥有'),
  memberOf('memberOf', '成员'),
  
  // 地理关系
  contains('contains', '包含'),
  containedBy('containedBy', '被包含'),
  adjacent('adjacent', '相邻'),
  
  // 其他关系
  uses('uses', '使用'),
  usedBy('usedBy', '被使用'),
  related('related', '相关'),
  
  // 自定义关系
  custom('custom', '自定义');

  const SettingRelationshipType(this.value, this.displayName);
  
  final String value;
  final String displayName;
  
  /// 根据值获取枚举
  static SettingRelationshipType fromValue(String value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => custom,
    );
  }
  
  /// 获取关系类型的反向关系
  SettingRelationshipType get inverse {
    switch (this) {
      case parent:
        return child;
      case child:
        return parent;
      case contains:
        return containedBy;
      case containedBy:
        return contains;
      case owns:
        return ownedBy;
      case ownedBy:
        return owns;
      case uses:
        return usedBy;
      case usedBy:
        return uses;
      default:
        return this; // 对称关系或自定义关系返回自身
    }
  }
  
  /// 判断是否为父子关系
  bool get isHierarchical {
    return this == parent || this == child;
  }
  
  /// 判断是否为对称关系（双向相同）
  bool get isSymmetric {
    const symmetricTypes = {
      friend,
      enemy,
      ally,
      rival,
      adjacent,
      related,
      custom,
    };
    return symmetricTypes.contains(this);
  }
  
  /// 按类别分组
  static Map<String, List<SettingRelationshipType>> get groupedTypes {
    return {
      '层级关系': [parent, child],
      '社会关系': [friend, enemy, ally, rival],
      '归属关系': [owns, ownedBy, memberOf],
      '地理关系': [contains, containedBy, adjacent],
      '功能关系': [uses, usedBy, related],
      '其他': [custom],
    };
  }
}