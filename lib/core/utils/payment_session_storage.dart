import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PaymentSessionStorage {
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'kashier_pending_session_id';
  static const _walletKey = 'kashier_pending_wallet_id';

  static Future<void> save({
    required String sessionId,
    required String walletId,
  }) async {
    await _storage.write(key: _sessionKey, value: sessionId);
    await _storage.write(key: _walletKey, value: walletId);
  }

  static Future<String?> readSessionId() => _storage.read(key: _sessionKey);
  static Future<String?> readWalletId() => _storage.read(key: _walletKey);

  static Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _walletKey);
  }
}
