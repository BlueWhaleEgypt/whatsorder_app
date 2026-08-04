// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'make_offer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MakeOfferRequest _$MakeOfferRequestFromJson(Map<String, dynamic> json) =>
    MakeOfferRequest(
      orderId: (json['orderId'] as num).toInt(),
      userId: json['userId'] as String,
      offerDetails: json['offerDetails'] as String,
    );

Map<String, dynamic> _$MakeOfferRequestToJson(MakeOfferRequest instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'userId': instance.userId,
      'offerDetails': instance.offerDetails,
    };
