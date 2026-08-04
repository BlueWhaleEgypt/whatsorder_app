import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:whats_order/features/auth/sign_in/data/sector_model_login.dart';

part 'user_model.g.dart';

/*
|--------------------------------------------------------------------------
| UserModel — minimal profile shape used inside SignInResponse.
|--------------------------------------------------------------------------
*/
@JsonSerializable()
class UserModel extends Equatable {
  final String? id;
  final String? username;
  final String? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? otpPhone;
  final bool? verifiedPhone;
  final double? serviceDistance;
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
  final List<SectorModelLogin>? sectors;
  final int? rate;
  final int? averageRate;
  final String? availForOrders;
  final bool? readLicense;

  const UserModel({
    this.id,
    this.username,
    this.phone,
    this.email,
    this.firstName,
    this.lastName,
    this.otpPhone,
    this.verifiedPhone,
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
    this.readLicense,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  List<Object?> get props => [
        id,
        username,
        phone,
        email,
        firstName,
        lastName,
        otpPhone,
        verifiedPhone,
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
        readLicense,
      ];
}
