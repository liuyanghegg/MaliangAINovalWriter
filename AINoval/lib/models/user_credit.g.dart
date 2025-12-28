// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_credit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCredit _$UserCreditFromJson(Map<String, dynamic> json) => $checkedCreate(
      'UserCredit',
      json,
      ($checkedConvert) {
        final val = UserCredit(
          userId: $checkedConvert('userId', (v) => v as String),
          credits: $checkedConvert('credits', (v) => (v as num).toInt()),
          creditToUsdRate: $checkedConvert(
              'creditToUsdRate', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserCreditToJson(UserCredit instance) {
  final val = <String, dynamic>{
    'userId': instance.userId,
    'credits': instance.credits,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('creditToUsdRate', instance.creditToUsdRate);
  return val;
}
