import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the sign-in token between app launches.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Stores the token in the platform keystore (Keychain on iOS, encrypted
/// storage on Android).
class SecureTokenStore implements TokenStore {
  const SecureTokenStore([this._key = 'cabo_token']);

  final String _key;
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      // Unreadable storage (for example after a restore to a new device)
      // is treated as signed out.
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

/// In-memory store for tests.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}
