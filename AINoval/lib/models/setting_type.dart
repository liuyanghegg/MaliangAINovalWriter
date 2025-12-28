// AINoval/lib/models/setting_type.dart
enum SettingType {
  character('CHARACTER', '角色'),
  location('LOCATION', '地点'),
  item('ITEM', '物品'),
  lore('LORE', '背景知识'),
  faction('FACTION', '组织/势力'),
  event('EVENT', '事件'),
  concept('CONCEPT', '概念/规则'),
  creature('CREATURE', '生物/种族'),
  magicSystem('MAGIC_SYSTEM', '魔法体系'),
  technology('TECHNOLOGY', '科技设定'),
  culture('CULTURE', '文化'),
  history('HISTORY', '历史'),
  organization('ORGANIZATION', '组织'),
  // —— 通用叙事/世界构建扩展 ——
  worldview('WORLDVIEW', '世界观'),
  pleasurePoint('PLEASURE_POINT', '爽点'),
  anticipationHook('ANTICIPATION_HOOK', '期待感钩子'),
  theme('THEME', '主题'),
  tone('TONE', '基调'),
  style('STYLE', '文风'),
  trope('TROPE', '母题/套路'),
  plotDevice('PLOT_DEVICE', '剧情装置'),
  powerSystem('POWER_SYSTEM', '力量体系'),
  goldenFinger('GOLDEN_FINGER', '金手指'),
  timeline('TIMELINE', '时间线'),
  religion('RELIGION', '宗教'),
  politics('POLITICS', '政治'),
  economy('ECONOMY', '经济'),
  geography('GEOGRAPHY', '地理'),
  other('OTHER', '其他');

  const SettingType(this.value, this.displayName);
  final String value;
  final String displayName;

  // 为了向后兼容，添加 key 属性
  String get key => value;

  static SettingType fromValue(String value) {
    return SettingType.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => SettingType.other,
    );
  }

  // 添加 JSON 序列化支持
  static SettingType fromJson(dynamic json) {
    if (json is String) {
      return fromValue(json);
    } else if (json is Map<String, dynamic>) {
      return fromValue(json['value'] ?? json['key'] ?? 'OTHER');
    }
    return SettingType.other;
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'displayName': displayName,
  };
}

// Helper for UI if needed
class SettingTypeOption {
  final SettingType type;
  bool isSelected;

  SettingTypeOption(this.type, {this.isSelected = false});
} 