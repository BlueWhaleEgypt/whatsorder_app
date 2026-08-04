// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmsMessageModel _$SmsMessageModelFromJson(Map<String, dynamic> json) =>
    SmsMessageModel(
      id: json['id'] as String,
      components: json['components'] as String?,
      title: json['title'] as String?,
      orderId: (json['orderId'] as num?)?.toInt(),
      userId: json['userId'] as String?,
      pressed: json['pressed'] as bool? ?? false,
    );

Map<String, dynamic> _$SmsMessageModelToJson(SmsMessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'components': instance.components,
      'title': instance.title,
      'orderId': instance.orderId,
      'userId': instance.userId,
      'pressed': instance.pressed,
    };
