import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

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
  };

  @override
  Future<Either<Failure, BaseRepository>> getData(dynamic request) async {
    if (request is! UpdateProfileRequest) {
      return const Left(ServerFailure('invalid_request'));
    }

    Directory? tempDirectory;

    try {
      final formData = FormData();

      // Add regular profile fields.
      request.fields.forEach((key, value) {
        if (_fileFields.contains(key)) return;

        formData.fields.add(MapEntry(key, value?.toString() ?? ''));
      });

      final downloadDio = Dio();

      // Add all existing or newly selected files as MultipartFile.
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

          logger.w('$fieldName: using newly selected file');
          continue;
        }

        final oldFileName = request.existingFileNames[fieldName];

        // No previous image exists for this field.
        if (oldFileName == null || oldFileName.isEmpty) {
          logger.w('$fieldName: no existing file');
          continue;
        }

        // Download the previous image from /uploads/.
        final imageUrl =
            '${EndPoints.baseUrl}/uploads/'
            '${Uri.encodeComponent(oldFileName)}';

        final downloadResponse = await downloadDio.get<List<int>>(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        final bytes = downloadResponse.data;

        if (bytes == null || bytes.isEmpty) {
          throw Exception('Could not download existing file: $oldFileName');
        }

        tempDirectory ??= await Directory.systemTemp.createTemp(
          'whats_order_profile_',
        );

        final tempFile = File('${tempDirectory.path}/$fieldName.tmp');

        await tempFile.writeAsBytes(bytes, flush: true);

        formData.files.add(
          MapEntry(
            fieldName,
            await MultipartFile.fromFile(tempFile.path, filename: oldFileName),
          ),
        );

        logger.w('$fieldName: reusing existing file $oldFileName');
      }

      final url =
          '${EndPoints.baseUrl}/api/auth/updateProfile/'
          '${request.userId}';

      logger.w('========== UPDATE PROFILE REQUEST ==========');
      logger.w('URL: $url');

      logger.w('========== REQUEST FIELDS ==========');
      for (final field in formData.fields) {
        logger.w('${field.key}: ${field.value}');
      }

      logger.w('========== REQUEST FILES ==========');
      for (final entry in formData.files) {
        logger.w(
          'Field: ${entry.key} | '
          'Filename: ${entry.value.filename}',
        );
      }

      final response = await DioHelper.putData(
        url: url,
        formDataOverride: formData,
      );

      final data = response.data;

      logger.w('========== UPDATE PROFILE RESPONSE ==========');
      logger.w('Status Code: ${response.statusCode}');
      logger.w('Response Data: $data');

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
      logger.e('Status Code: ${e.response?.statusCode}');
      logger.e('Response Data: $responseData');
      logger.e('Error: ${e.message}');

      final message = responseData is Map
          ? responseData['message']?.toString()
          : null;

      return Left(ServerFailure(message ?? 'profile_update_failed'));
    } catch (e, stackTrace) {
      logger.e('Update profile exception: $e');
      logger.e('Stack trace: $stackTrace');

      return const Left(ServerFailure('something_went_wrong'));
    } finally {
      if (tempDirectory != null && await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
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
