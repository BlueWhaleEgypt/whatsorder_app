import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_model.g.dart';

@JsonSerializable()
class VendorModel extends Equatable {
  final String? id;
  final String? username;
  final String? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool? verifiedPhone;
  final String? type;
  final double? serviceDistance;

  @JsonKey(name: 'chat_id')
  final String? chatId;

  final double? latitude;
  final double? longitude;
  final String? createdDate;
  final bool? activation;
  final int? usedReferralNumber;
  final List<String>? rolesStr;
  final List<String>? privilegesStr;
  final String? city;
  final String? state;
  final bool? servingTheEntireGovernorate;
  final bool? servingTheEntireArea;
  final bool? availableInAllRegions;
  final String? faceIdCard;
  final String? backIdCard;
  final String? commercialRegister;
  final List<VendorSectorModel>? sectors;
  final double? rate;
  final double? averageRate;
  final String? availForOrders;

  @JsonKey(name: 'activation_date')
  final String? activationDate;

  final String? verificationStatus;
  final bool? whatsappNotificationsEnabled;
  final int? freeWhatsappMessagesUsed;
  final int? trialDays;
  final bool? firstLogin;
  final bool? readLicense;

  const VendorModel({
    this.id,
    this.username,
    this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.verifiedPhone,
    this.type,
    this.serviceDistance,
    this.chatId,
    this.latitude,
    this.longitude,
    this.createdDate,
    this.activation,
    this.usedReferralNumber,
    this.rolesStr,
    this.privilegesStr,
    this.city,
    this.state,
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
    this.activationDate,
    this.verificationStatus,
    this.whatsappNotificationsEnabled,
    this.freeWhatsappMessagesUsed,
    this.trialDays,
    this.firstLogin,
    this.readLicense,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) =>
      _$VendorModelFromJson(json);

  Map<String, dynamic> toJson() => _$VendorModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        username,
        phone,
        email,
        firstName,
        lastName,
        verifiedPhone,
        type,
        serviceDistance,
        chatId,
        latitude,
        longitude,
        createdDate,
        activation,
        usedReferralNumber,
        rolesStr,
        privilegesStr,
        city,
        state,
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
        activationDate,
        verificationStatus,
        whatsappNotificationsEnabled,
        freeWhatsappMessagesUsed,
        trialDays,
        firstLogin,
        readLicense,
      ];
}

@JsonSerializable()
class VendorSectorModel extends Equatable {
  final String? id;
  final String? name;
  final String? note;
  final double? cost;
  final bool? view;

  const VendorSectorModel({
    this.id,
    this.name,
    this.note,
    this.cost,
    this.view,
  });

  factory VendorSectorModel.fromJson(Map<String, dynamic> json) =>
      _$VendorSectorModelFromJson(json);

  Map<String, dynamic> toJson() => _$VendorSectorModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        note,
        cost,
        view,
      ];
}