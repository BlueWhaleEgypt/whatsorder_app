// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_checkout_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentCheckoutRequest _$PaymentCheckoutRequestFromJson(
  Map<String, dynamic> json,
) => PaymentCheckoutRequest(
  amount: json['amount'] as num,
  currency: json['currency'] as String,
  order: json['order'] as String,
  customerEmail: json['customerEmail'] as String,
  redirectUrl: json['redirectUrl'] as String,
  webhookUrl: json['webhookUrl'] as String,
);

Map<String, dynamic> _$PaymentCheckoutRequestToJson(
  PaymentCheckoutRequest instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'currency': instance.currency,
  'order': instance.order,
  'customerEmail': instance.customerEmail,
  'redirectUrl': instance.redirectUrl,
  'webhookUrl': instance.webhookUrl,
};
