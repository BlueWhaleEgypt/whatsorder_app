// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sector_model_login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SectorModelLogin _$SectorModelLoginFromJson(Map<String, dynamic> json) =>
    SectorModelLogin(
      id: json['id'] as String?,
      name: json['name'] as String?,
      note: json['note'] as String?,
      cost: json['cost'] as num?,
      view: json['view'] as bool?,
    );

Map<String, dynamic> _$SectorModelLoginToJson(SectorModelLogin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'note': instance.note,
      'cost': instance.cost,
      'view': instance.view,
    };
