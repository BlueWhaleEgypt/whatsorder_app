import 'package:json_annotation/json_annotation.dart';
part 'make_offer_request.g.dart';

@JsonSerializable()
class MakeOfferRequest {
  final int orderId;
  final String userId;
  final String offerDetails;

  const MakeOfferRequest({
    required this.orderId,
    required this.userId,
    required this.offerDetails,
  });

  factory MakeOfferRequest.fromJson(Map<String, dynamic> json) =>
      _$MakeOfferRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MakeOfferRequestToJson(this);
}
