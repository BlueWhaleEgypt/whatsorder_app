// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_messages_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SmsMessagesResponse _$SmsMessagesResponseFromJson(Map<String, dynamic> json) =>
    SmsMessagesResponse(
      smsMessages:
          (json['smsMessages'] as List<dynamic>?)
              ?.map((e) => SmsMessageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SmsMessagesResponseToJson(
  SmsMessagesResponse instance,
) => <String, dynamic>{'smsMessages': instance.smsMessages};
