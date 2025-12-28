import 'package:ainoval/models/ai_request_models.dart';

/// 通用AI请求仓库接口
abstract class UniversalAIRepository {
  /// 发送通用AI请求（非流式）
  Future<UniversalAIResponse> sendRequest(UniversalAIRequest request);

  /// 发送通用AI请求（流式）
  Stream<UniversalAIResponse> streamRequest(UniversalAIRequest request);

  /// 预览请求（获取构建的提示内容，不实际发送给AI）
  Future<UniversalAIPreviewResponse> previewRequest(UniversalAIRequest request);
  
  /// 🚀 新增：预估积分成本
  /// 快速预估AI请求的积分消耗，不实际发送给AI
  Future<CostEstimationResponse> estimateCost(UniversalAIRequest request);
} 