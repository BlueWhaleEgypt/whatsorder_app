import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/network/dio_helper.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_request.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_response.dart';

import 'helpers/harness.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _vendor = VendorModel(
  id: 'v1',
  firstName: 'Ahmed',
  faceIdCard: '1795510380874face.jpg',
  backIdCard: '1795510380874back.jpg',
  commercialRegister: '1795510380874register.jpg',
  storePhoto: '1795510380874store.jpg',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CaptureAdapter adapter;
  late Directory tmp;

  setUp(() async {
    await initPrefs();
    DioHelper.init();
    adapter = _CaptureAdapter();
    DioHelper.dio.httpClientAdapter = adapter;
    tmp = await Directory.systemTemp.createTemp('upload_test_');
  });

  tearDown(() async => tmp.delete(recursive: true));

  Map<String, String?> sentNames() {
    final form = adapter.requests.single.data as FormData;
    return {for (final f in form.files) f.key: f.value.filename};
  }

  test('noPhoto.jpeg asset exists and is a JPEG', () {
    final bytes = File(UpdateProfileRequest.noPhotoAsset).readAsBytesSync();
    expect(bytes.sublist(0, 2), [0xFF, 0xD8]);
  });

  test('unchanged images are all sent as noPhoto.jpeg', () async {
    await UpdateProfileResponse().getData(
      UpdateProfileRequest.fromVendor(userId: 'v1', vendor: _vendor),
    );

    expect(adapter.requests, hasLength(1)); // no image downloads
    expect(sentNames(), {
      'faceIdCard': 'noPhoto.jpeg',
      'backIdCard': 'noPhoto.jpeg',
      'commercialRegister': 'noPhoto.jpeg',
      'storePhoto': 'noPhoto.jpeg',
    });
  });

  test('a replaced image is uploaded; the rest stay noPhoto.jpeg', () async {
    final picked = File('${tmp.path}/new_face.jpg')
      ..writeAsBytesSync([1, 2, 3]);

    await UpdateProfileResponse().getData(
      UpdateProfileRequest.fromVendor(
        userId: 'v1',
        vendor: _vendor,
        files: {'faceIdCard': picked},
        storePhoto: File('${tmp.path}/new_store.png')
          ..writeAsBytesSync([4, 5, 6]),
      ),
    );

    expect(sentNames(), {
      'faceIdCard': 'new_face.jpg',
      'backIdCard': 'noPhoto.jpeg',
      'commercialRegister': 'noPhoto.jpeg',
      'storePhoto': 'new_store.png',
    });
  });

  test('old file names never appear in the request', () async {
    await UpdateProfileResponse().getData(
      UpdateProfileRequest.fromVendor(userId: 'v1', vendor: _vendor),
    );

    final form = adapter.requests.single.data as FormData;
    expect(
      form.files.map((f) => f.value.filename).join(),
      isNot(contains('1795510380874')),
    );
    expect(form.fields.map((f) => f.value).join(), isNot(contains('1795510')));
  });
}
