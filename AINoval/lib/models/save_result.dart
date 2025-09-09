/// 保存设定结果
/// 
/// 对应后端 SaveSettingResponse 的结构
/// 
/// 包含保存成功后返回的重要信息
class SaveResult {
  /// 保存是否成功
  final bool success;
  
  /// 返回消息
  final String message;
  
  /// 根设定ID列表
  final List<String> rootSettingIds;
  
  /// 自动创建的历史记录ID
  final String? historyId;

  const SaveResult({
    required this.success,
    required this.message,
    required this.rootSettingIds,
    this.historyId,
  });

  factory SaveResult.fromJson(Map<String, dynamic> json) {
    return SaveResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      rootSettingIds: (json['rootSettingIds'] as List<dynamic>?)?.cast<String>() ?? [],
      historyId: json['historyId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'rootSettingIds': rootSettingIds,
    if (historyId != null) 'historyId': historyId,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaveResult &&
        other.success == success &&
        other.message == message &&
        other.historyId == historyId;
  }

  @override
  int get hashCode => success.hashCode ^ message.hashCode ^ historyId.hashCode;

  @override
  String toString() => 'SaveResult(success: $success, message: $message, historyId: $historyId)';
}