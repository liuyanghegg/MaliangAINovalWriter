/// API异常类
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}



/// 🚀 新增：积分不足异常
/// 当用户积分余额不足时抛出
class InsufficientCreditsException extends ApiException {
  final int? requiredCredits;
  
  InsufficientCreditsException(String message, [this.requiredCredits])
      : super(402, message); // HTTP 402 Payment Required
  
  /// 从错误消息中提取需要的积分数量
  static int? extractRequiredCredits(String message) {
    final regex = RegExp(r'需要 (\d+) 积分');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
  
  /// 创建带有自动提取积分数量的实例
  factory InsufficientCreditsException.fromMessage(String message) {
    final requiredCredits = extractRequiredCredits(message);
    return InsufficientCreditsException(message, requiredCredits);
  }
} 