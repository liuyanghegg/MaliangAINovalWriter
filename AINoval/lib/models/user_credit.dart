import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_credit.g.dart';

/// 用户积分模型
@JsonSerializable()
class UserCredit extends Equatable {
  /// 用户ID
  final String userId;
  
  /// 积分余额
  final int credits;
  
  /// 积分与美元汇率（可选）
  final double? creditToUsdRate;

  const UserCredit({
    required this.userId,
    required this.credits,
    this.creditToUsdRate,
  });

  factory UserCredit.fromJson(Map<String, dynamic> json) =>
      _$UserCreditFromJson(json);

  Map<String, dynamic> toJson() => _$UserCreditToJson(this);

  @override
  List<Object?> get props => [userId, credits, creditToUsdRate];

  /// 获取格式化的积分显示文本
  String get formattedCredits {
    if (credits >= 1000000) {
      return '${(credits / 1000000).toStringAsFixed(1)}M';
    } else if (credits >= 1000) {
      return '${(credits / 1000).toStringAsFixed(1)}K';
    } else {
      return credits.toString();
    }
  }

  /// 获取等值美元显示（如果有汇率信息）
  String get equivalentUsd {
    if (creditToUsdRate != null && creditToUsdRate! > 0) {
      final usd = credits / creditToUsdRate!;
      return '\$${usd.toStringAsFixed(2)}';
    }
    return '';
  }

  /// 检查是否有足够积分
  bool hasEnoughCredits(int required) {
    return credits >= required;
  }

  /// 创建空积分对象
  factory UserCredit.empty() {
    return const UserCredit(
      userId: '',
      credits: 0,
    );
  }
} 