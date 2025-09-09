/// 小说导入状态模型
class ImportStatus {
  /// 从JSON创建实例
  factory ImportStatus.fromJson(Map<String, dynamic> json) {
    return ImportStatus(
      status: json['status'] as String,
      message: json['message'] as String,
      progress: (json['progress'] as num?)?.toDouble(),
      currentStep: json['currentStep'] as String?,
      processedChapters: json['processedChapters'] as int?,
      totalChapters: json['totalChapters'] as int?,
    );
  }

  /// 创建导入状态
  ImportStatus({
    required this.status,
    required this.message,
    this.progress,
    this.currentStep,
    this.processedChapters,
    this.totalChapters,
  });

  /// 导入状态 (PROCESSING, SAVING, INDEXING, COMPLETED, FAILED, ERROR)
  final String status;

  /// 状态消息
  final String message;

  /// 导入进度 (0.0 - 1.0)
  final double? progress;

  /// 当前步骤描述
  final String? currentStep;

  /// 已处理章节数
  final int? processedChapters;

  /// 总章节数
  final int? totalChapters;

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      if (progress != null) 'progress': progress,
      if (currentStep != null) 'currentStep': currentStep,
      if (processedChapters != null) 'processedChapters': processedChapters,
      if (totalChapters != null) 'totalChapters': totalChapters,
    };
  }

  @override
  String toString() => 'ImportStatus{status: $status, message: $message, progress: $progress, currentStep: $currentStep, processedChapters: $processedChapters, totalChapters: $totalChapters}';
}
