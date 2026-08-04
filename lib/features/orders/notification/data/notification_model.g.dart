// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String?,
      components: json['components'] as String?,
      title: json['title'] as String?,
      orderId: (json['orderId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      pressed: json['pressed'] as bool?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'components': instance.components,
      'title': instance.title,
      'orderId': instance.orderId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'pressed': instance.pressed,
    };
