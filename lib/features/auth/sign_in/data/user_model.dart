import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/features/auth/sign_in/data/sector_model_login.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String? id;
  final String? companyName;
  final String? username;
  final String? phone;
  final String? email;
  final String? photo;
  final String? firstName;
  final String? lastName;

  final String? otpPhone;
  final bool? verifiedPhone;
  final String? otpEmail;
  final String? type;

  final double? serviceDistance;

  final bool? verifiedEmail;
  final String? chatId;
  final String? supplierCode;
  final double? couponsValue;
  final String? communicationResponsible;

  final double? latitude;
  final double? longitude;

  final String? referralCoupon;
  final String? employeeCode;
  final String? createdDate;
  final String? userId;
  final String? sectorId;
  final String? myOwnReferalCoupon;
  final String? referralEmail;
  final String? perthDate;

  final bool? activation;
  final String? googleId;
  final int? usedReferralNumber;

  final List<String>? rolesStr;
  final List<String>? privilegesStr;

  final String? city;
  final String? state;
  final String? street;
  final String? building;
  final String? area;
  final String? neighborhood;
  final String? governorate;

  final bool? servingTheEntireGovernorate;
  final bool? servingTheEntireArea;
  final bool? availableInAllRegions;

  final String? faceIdCard;
  final String? backIdCard;
  final String? commercialRegister;

  final List<SectorModelLogin>? sectors;

  final double? rate;
  final double? averageRate;

  final String? availForOrders;
  final String? keyWords;

  final String? activationDate;
  final String? verificationStatus;
  final String? verificationDate;
  final String? trialExpiryDate;

  final bool? whatsappNotificationsEnabled;
  final int? freeWhatsappMessagesUsed;
  final int? trialDays;
  final bool? readLicense;

  const UserModel({
    this.id,
    this.companyName,
    this.username,
    this.phone,
    this.email,
    this.photo,
    this.firstName,
    this.lastName,
    this.otpPhone,
    this.verifiedPhone,
    this.otpEmail,
    this.type,
    this.serviceDistance,
    this.verifiedEmail,
    this.chatId,
    this.supplierCode,
    this.couponsValue,
    this.communicationResponsible,
    this.latitude,
    this.longitude,
    this.referralCoupon,
    this.employeeCode,
    this.createdDate,
    this.userId,
    this.sectorId,
    this.myOwnReferalCoupon,
    this.referralEmail,
    this.perthDate,
    this.activation,
    this.googleId,
    this.usedReferralNumber,
    this.rolesStr,
    this.privilegesStr,
    this.city,
    this.state,
    this.street,
    this.building,
    this.area,
    this.neighborhood,
    this.governorate,
    this.servingTheEntireGovernorate,
    this.servingTheEntireArea,
    this.availableInAllRegions,
    this.faceIdCard,
    this.backIdCard,
    this.commercialRegister,
    this.sectors,
    this.rate,
    this.averageRate,
    this.availForOrders,
    this.keyWords,
    this.activationDate,
    this.verificationStatus,
    this.verificationDate,
    this.trialExpiryDate,
    this.whatsappNotificationsEnabled,
    this.freeWhatsappMessagesUsed,
    this.trialDays,
    this.readLicense,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    companyName,
    username,
    phone,
    email,
    photo,
    firstName,
    lastName,
    otpPhone,
    verifiedPhone,
    otpEmail,
    type,
    serviceDistance,
    verifiedEmail,
    chatId,
    supplierCode,
    couponsValue,
    communicationResponsible,
    latitude,
    longitude,
    referralCoupon,
    employeeCode,
    createdDate,
    userId,
    sectorId,
    myOwnReferalCoupon,
    referralEmail,
    perthDate,
    activation,
    googleId,
    usedReferralNumber,
    rolesStr,
    privilegesStr,
    city,
    state,
    street,
    building,
    area,
    neighborhood,
    governorate,
    servingTheEntireGovernorate,
    servingTheEntireArea,
    availableInAllRegions,
    faceIdCard,
    backIdCard,
    commercialRegister,
    sectors,
    rate,
    averageRate,
    availForOrders,
    keyWords,
    activationDate,
    verificationStatus,
    verificationDate,
    trialExpiryDate,
    whatsappNotificationsEnabled,
    freeWhatsappMessagesUsed,
    trialDays,
    readLicense,
  ];
}
