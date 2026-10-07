// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorModel _$VendorModelFromJson(Map<String, dynamic> json) => VendorModel(
  id: json['id'] as String?,
  username: json['username'] as String?,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  verifiedPhone: json['verifiedPhone'] as bool?,
  type: json['type'] as String?,
  serviceDistance: (json['serviceDistance'] as num?)?.toDouble(),
  chatId: json['chat_id'] as String?,
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
      ?.map((e) => VendorSectorModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  rate: (json['rate'] as num?)?.toDouble(),
  averageRate: (json['averageRate'] as num?)?.toDouble(),
  availForOrders: json['availForOrders'] as String?,
  activationDate: json['activation_date'] as String?,
  verificationStatus: json['verificationStatus'] as String?,
  whatsappNotificationsEnabled: json['whatsappNotificationsEnabled'] as bool?,
  freeWhatsappMessagesUsed: (json['freeWhatsappMessagesUsed'] as num?)?.toInt(),
  trialDays: (json['trialDays'] as num?)?.toInt(),
  firstLogin: json['firstLogin'] as bool?,
  readLicense: json['readLicense'] as bool?,
);

Map<String, dynamic> _$VendorModelToJson(VendorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'phone': instance.phone,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'verifiedPhone': instance.verifiedPhone,
      'type': instance.type,
      'serviceDistance': instance.serviceDistance,
      'chat_id': instance.chatId,
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
      'activation_date': instance.activationDate,
      'verificationStatus': instance.verificationStatus,
      'whatsappNotificationsEnabled': instance.whatsappNotificationsEnabled,
      'freeWhatsappMessagesUsed': instance.freeWhatsappMessagesUsed,
      'trialDays': instance.trialDays,
      'firstLogin': instance.firstLogin,
      'readLicense': instance.readLicense,
    };

VendorSectorModel _$VendorSectorModelFromJson(Map<String, dynamic> json) =>
    VendorSectorModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      note: json['note'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      view: json['view'] as bool?,
    );

Map<String, dynamic> _$VendorSectorModelToJson(VendorSectorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'note': instance.note,
      'cost': instance.cost,
      'view': instance.view,
    };
