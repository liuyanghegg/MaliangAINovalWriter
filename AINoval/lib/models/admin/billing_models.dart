class CreditTransactionModel {
  final String traceId;
  final String? userId;
  final String? provider;
  final String? modelId;
  final String? featureType;
  final int? inputTokens;
  final int? outputTokens;
  final int? creditsDeducted;
  final String status; // PENDING, DEDUCTED, FAILED, COMPENSATED
  final String? errorMessage;
  final String? reversalOfTraceId;
  final String? operatorUserId;
  final String? auditNote;
  final String? createdAt; // ISO8601 from backend

  CreditTransactionModel({
    required this.traceId,
    required this.status,
    this.userId,
    this.provider,
    this.modelId,
    this.featureType,
    this.inputTokens,
    this.outputTokens,
    this.creditsDeducted,
    this.errorMessage,
    this.reversalOfTraceId,
    this.operatorUserId,
    this.auditNote,
    this.createdAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      traceId: (json['traceId'] ?? '').toString(),
      userId: json['userId']?.toString(),
      provider: json['provider']?.toString(),
      modelId: json['modelId']?.toString(),
      featureType: json['featureType']?.toString(),
      inputTokens: json['inputTokens'] is int ? json['inputTokens'] as int : int.tryParse('${json['inputTokens'] ?? ''}'),
      outputTokens: json['outputTokens'] is int ? json['outputTokens'] as int : int.tryParse('${json['outputTokens'] ?? ''}'),
      creditsDeducted: json['creditsDeducted'] is int ? json['creditsDeducted'] as int : int.tryParse('${json['creditsDeducted'] ?? ''}'),
      status: (json['status'] ?? '').toString(),
      errorMessage: json['errorMessage']?.toString(),
      reversalOfTraceId: json['reversalOfTraceId']?.toString(),
      operatorUserId: json['operatorUserId']?.toString(),
      auditNote: json['auditNote']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}


