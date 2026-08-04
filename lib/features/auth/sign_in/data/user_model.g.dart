// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String?,
  username: json['username'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  otpPhone: json['otpPhone'] as String?,
  verifiedPhone: json['verifiedPhone'] as bool?,
  serviceDistance: (json['serviceDistance'] as num?)?.toDouble(),
  chatId: json['chatId'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  createdDate: json['createdDate'] as String?,
  activation: json['activation'] as bool?,
  usedReferralNumber: (json['usedReferralNumber'] as num?)?.toInt(),
  rolesStr: (json['rolesStr'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  privilegesStr: (json['privilegesStr'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  city: json['city'] as String?,
  state: json['state'] as String?,
  servingTheEntireGovernorate: json['servingTheEntireGovernorate'] as bool?,
  servingTheEntireArea: json['servingTheEntireArea'] as bool?,
  availableInAllRegions: json['availableInAllRegions'] as bool?,
  faceIdCard: json['faceIdCard'] as String?,
  backIdCard: json['backIdCard'] as String?,
  commercialRegister: json['commercialRegister'] as String?,
  sectors: (json['sectors'] as List<dynamic>?)
      ?.map((e) => SectorModelLogin.fromJson(e as Map<String, dynamic>))
      .toList(),
  rate: (json['rate'] as num?)?.toInt(),
  averageRate: (json['averageRate'] as num?)?.toInt(),
  availForOrders: json['availForOrders'] as String?,
  readLicense: json['readLicense'] as bool?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'phone': instance.phone,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'otpPhone': instance.otpPhone,
  'verifiedPhone': instance.verifiedPhone,
  'serviceDistance': instance.serviceDistance,
  'chatId': instance.chatId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'createdDate': instance.createdDate,
  'activation': instance.activation,
  'usedReferralNumber': instance.usedReferralNumber,
  'rolesStr': instance.rolesStr,
  'privilegesStr': instance.privilegesStr,
  'city': instance.city,
  'state': instance.state,
  'servingTheEntireGovernorate': instance.servingTheEntireGovernorate,
  'servingTheEntireArea': instance.servingTheEntireArea,
  'availableInAllRegions': instance.availableInAllRegions,
  'faceIdCard': instance.faceIdCard,
  'backIdCard': instance.backIdCard,
  'commercialRegister': instance.commercialRegister,
  'sectors': instance.sectors,
  'rate': instance.rate,
  'averageRate': instance.averageRate,
  'availForOrders': instance.availForOrders,
  'readLicense': instance.readLicense,
};
