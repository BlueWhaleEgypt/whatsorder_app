import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';

/// Store fields of the backend `UserDto` that the store profile screen edits.
class StoreProfile extends Equatable {
  final String name;
  final String phone;
  final bool verifiedPhone;
  final String? photo;
  final String slug;
  final String about;
  final String address;
  final String opensAt; // HH:mm
  final String closesAt; // HH:mm
  final num deliveryFee;
  final List<String> workingDays; // e.g. SUNDAY
  final List<String> deliveryAreas;
  final bool acceptNewOrders;
  final bool showPrices;
  final bool askForDeliveryAddress;
  final bool cashOnDelivery;
  final bool onlinePayment;

  const StoreProfile({
    this.name = '',
    this.phone = '',
    this.verifiedPhone = false,
    this.photo,
    this.slug = '',
    this.about = '',
    this.address = '',
    this.opensAt = '10:00',
    this.closesAt = '23:00',
    this.deliveryFee = 0,
    this.workingDays = const [],
    this.deliveryAreas = const [],
    this.acceptNewOrders = true,
    this.showPrices = true,
    this.askForDeliveryAddress = true,
    this.cashOnDelivery = true,
    this.onlinePayment = false,
  });

  static String _hhmm(dynamic v, String fallback) {
    final s = v?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : fallback;
  }

  factory StoreProfile.fromJson(Map<String, dynamic> j) {
    final first = j['firstName']?.toString() ?? '';
    final last = j['lastName']?.toString() ?? '';
    final photo = (j['storePhoto'] ?? '').toString();
    return StoreProfile(
      name: (j['companyName'] ?? '$first $last').toString().trim(),
      phone: (j['phone'] ?? '').toString(),
      verifiedPhone: j['verifiedPhone'] == true,
      photo: photo.isEmpty ? null : photo,
      slug: (j['storeSlug'] ?? '').toString(),
      about: (j['storeAbout'] ?? '').toString(),
      address: (j['street'] ?? '').toString(),
      opensAt: _hhmm(j['storeOpensAt'], '10:00'),
      closesAt: _hhmm(j['storeClosesAt'], '23:00'),
      deliveryFee: (j['storeDeliveryFee'] as num?) ?? 0,
      workingDays: [
        for (final d in (j['workingDays'] as List?) ?? const [])
          d.toString().toUpperCase(),
      ],
      deliveryAreas: [
        for (final a in (j['deliveryAreas'] as List?) ?? const [])
          if (a is Map && a['name'] != null) a['name'].toString(),
      ],
      acceptNewOrders: j['acceptNewOrders'] != false,
      showPrices: j['showPrices'] != false,
      askForDeliveryAddress: j['askForDeliveryAddress'] != false,
      cashOnDelivery: j['cashOnDelivery'] != false,
      onlinePayment: j['onlinePayment'] == true,
    );
  }

  @override
  List<Object?> get props => [
    name,
    phone,
    verifiedPhone,
    photo,
    slug,
    about,
    address,
    opensAt,
    closesAt,
    deliveryFee,
    workingDays,
    deliveryAreas,
    acceptNewOrders,
    showPrices,
    askForDeliveryAddress,
    cashOnDelivery,
    onlinePayment,
  ];
}

abstract class StoreProfileRequest {
  const StoreProfileRequest();
}

class LoadStoreProfileRequest extends StoreProfileRequest {
  const LoadStoreProfileRequest();
}

class SaveStoreProfileRequest extends StoreProfileRequest {
  final StoreProfile profile;
  final File? newPhoto;
  const SaveStoreProfileRequest(this.profile, {this.newPhoto});
}

/// Talks to `GET /api/auth/vendors/{id}`, `PUT /api/auth/storeProfile/{id}`,
/// `PATCH /api/auth/storeOrdering/{id}` and `PUT /api/auth/deliveryAreas/{id}`.
class StoreProfileResponse extends Equatable implements BaseRepository {
  final StoreProfile? profile;

  const StoreProfileResponse({this.profile});

  @override
  List<Object?> get props => [profile];

  static String? get _userId {
    final user = UserModel.fromJson(
      jsonDecode(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
            '{}',
      ),
    );
    return user.id;
  }

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    final id = _userId;
    if (id == null || id.isEmpty) {
      return const Left(ServerFailure('current_user_not_identified'));
    }
    try {
      if (request is SaveStoreProfileRequest) {
        return await _save(id, request);
      }
      final res = await DioHelper.getData(
        url: '${EndPoints.baseUrl}${EndPoints.epGetVendorById}/$id',
      );
      return Right(
        StoreProfileResponse(
          profile: StoreProfile.fromJson(
            Map<String, dynamic>.from(res.data as Map),
          ),
        ),
      );
    } on DioException catch (e) {
      logger.e('StoreProfile ${e.response?.statusCode}: ${e.response?.data}');
      final data = e.response?.data;
      final msg = data is Map
          ? (data['message'] ?? data['detail'] ?? data['title'])?.toString()
          : null;
      return Left(ServerFailure(msg ?? 'something_went_wrong'));
    } catch (e) {
      logger.e('StoreProfile error: $e');
      return const Left(ServerFailure('something_went_wrong'));
    }
  }

  Future<Either<Failure, BaseRepository>> _save(
    String id,
    SaveStoreProfileRequest r,
  ) async {
    final p = r.profile;
    const base = EndPoints.baseUrl;

    final form = FormData();
    form.fields
      ..add(MapEntry('name', p.name))
      ..add(MapEntry('slug', p.slug))
      ..add(MapEntry('about', p.about))
      ..add(MapEntry('address', p.address))
      ..add(MapEntry('opensAt', p.opensAt))
      ..add(MapEntry('closesAt', p.closesAt))
      ..add(MapEntry('deliveryFee', p.deliveryFee.toString()));
    for (final d in p.workingDays) {
      form.fields.add(MapEntry('workingDays', d));
    }
    if (r.newPhoto != null) {
      form.files.add(
        MapEntry('photo', await MultipartFile.fromFile(r.newPhoto!.path)),
      );
    }

    await DioHelper.putData(
      url: '$base${EndPoints.epStoreProfile}/$id',
      formDataOverride: form,
    );

    await DioHelper.patchData(
      url: '$base${EndPoints.epStoreOrdering}/$id',
      body: {
        'acceptNewOrders': p.acceptNewOrders,
        'showPrices': p.showPrices,
        'askForDeliveryAddress': p.askForDeliveryAddress,
        'cashOnDelivery': p.cashOnDelivery,
        'onlinePayment': p.onlinePayment,
      },
    );

    final res = await DioHelper.putJson(
      url: '$base${EndPoints.epDeliveryAreas}/$id',
      data: [
        for (final a in p.deliveryAreas) {'name': a},
      ],
    );

    return Right(
      StoreProfileResponse(
        profile: res.data is Map
            ? StoreProfile.fromJson(Map<String, dynamic>.from(res.data as Map))
            : p,
      ),
    );
  }
}
