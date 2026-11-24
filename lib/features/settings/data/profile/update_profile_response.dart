import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:whats_order/base/base_repository.dart';
import 'package:whats_order/core/error/failures.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/utils/logger.dart';

import 'update_profile_request.dart';

class UpdateProfileResponse implements BaseRepository {
  static const Set<String> _fileFields = {
    'faceIdCard',
    'backIdCard',
    'commercialRegister',
    'storePhoto',
  };

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    if (request is! UpdateProfileRequest) {
      return const Left(ServerFailure('invalid_request'));
    }

    try {
      final formData = FormData();

      // Add regular profile fields.
      request.fields.forEach((key, value) {
        if (_fileFields.contains(key)) return;

        formData.fields.add(MapEntry(key, value?.toString() ?? ''));
      });

      // Backend contract: a field the user did not replace must be sent as
      // `noPhoto.jpeg`; the server then keeps its stored image. Existing
      // images are never downloaded or re-uploaded under their old names.
      Uint8List? noPhotoBytes;

      for (final fieldName in _fileFields) {
        final newFile = request.files[fieldName];

        if (newFile != null) {
          if (!await newFile.exists()) {
            throw FileSystemException(
              'Selected file does not exist',
              newFile.path,
            );
          }

          formData.files.add(
            MapEntry(fieldName, await MultipartFile.fromFile(newFile.path)),
          );
          continue;
        }

        noPhotoBytes ??= (await rootBundle.load(
          UpdateProfileRequest.noPhotoAsset,
        )).buffer.asUint8List();

        formData.files.add(
          MapEntry(
            fieldName,
            MultipartFile.fromBytes(
              noPhotoBytes,
              filename: UpdateProfileRequest.noPhotoFileName,
            ),
          ),
        );
      }

      final url =
          '${EndPoints.baseUrl}/api/auth/updateProfile/'
          '${request.userId}';

      // logger.w('========== UPDATE PROFILE REQUEST ==========');
      // logger.w('URL: $url');

      // logger.w('========== REQUEST FIELDS ==========');
      // for (final field in formData.fields) {
      //   logger.w('${field.key}: ${field.value}');
      // }

      // logger.w('========== REQUEST FILES ==========');
      // for (final entry in formData.files) {
      //   logger.w(
      //     'Field: ${entry.key} | '
      //     'Filename: ${entry.value.filename}',
      //   );
      // }

      final response = await DioHelper.putData(
        url: url,
        formDataOverride: formData,
      );

      final data = response.data;

      // logger.w('========== UPDATE PROFILE RESPONSE ==========');
      // logger.w('Status Code: ${response.statusCode}');
      // logger.w('Response Data: $data');
      // logger.i(
      //   'profile store API response:\n${AppLogPrinter.formatJson(data)}',
      // );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return Right(
          UpdateProfileResult(
            message: 'profile_updated_successfully',
            data: data,
          ),
        );
      }

      return const Left(ServerFailure('profile_update_failed'));
    } on DioException catch (e) {
      final responseData = e.response?.data;

      logger.e('========== UPDATE PROFILE ERROR ==========');
      logger.e('URL: ${e.requestOptions.uri}');
      logger.e('Status Code: ${e.response?.statusCode}');
      logger.e('Response Data: $responseData');
      logger.e('Error: ${e.message}');

      final message = responseData is Map
          ? responseData['message']?.toString()
          : null;

      return Left(ServerFailure(message ?? 'profile_update_failed'));
    } catch (e) {
      logger.e('Update profile exception: $e');

      return const Left(ServerFailure('something_went_wrong'));
    }
  }
}

class UpdateProfileResult implements BaseRepository {
  final String message;
  final dynamic data;

  const UpdateProfileResult({required this.message, this.data});

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    return const Left(ServerFailure('Unsupported operation'));
  }
}
