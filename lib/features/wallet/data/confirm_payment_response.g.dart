// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_payment_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfirmPaymentResponse _$ConfirmPaymentResponseFromJson(
  Map<String, dynamic> json,
) => ConfirmPaymentResponse(
  sessionId: json['sessionId'] as String?,
  status: json['status'] as String?,
  amount: json['amount'] as num?,
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$ConfirmPaymentResponseToJson(
  ConfirmPaymentResponse instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'status': instance.status,
  'amount': instance.amount,
  'currency': instance.currency,
};
