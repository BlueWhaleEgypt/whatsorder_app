import 'package:json_annotation/json_annotation.dart';

part 'payment_checkout_request.g.dart';

@JsonSerializable()
class PaymentCheckoutRequest {
  final num amount;
  final String currency;
  final String order;
  final String customerEmail;
  final String redirectUrl;
  final String webhookUrl;

  const PaymentCheckoutRequest({
    required this.amount,
    required this.currency,
    required this.order,
    required this.customerEmail,
    required this.redirectUrl,
    required this.webhookUrl,
  });

  factory PaymentCheckoutRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCheckoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentCheckoutRequestToJson(this);
}
