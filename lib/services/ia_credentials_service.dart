import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// IA S3 authentication keys (from archive.org account settings).
///
/// [toString] is deliberately redacted: key material must never leak into
/// logs, error reports, or the UI (#95).
@immutable
class IAS3Keys {
  final String accessKey;
  final String secretKey;

  const IAS3Keys({required this.accessKey, required this.secretKey});

  bool get isValid => accessKey.isNotEmpty && secretKey.isNotEmpty;

  /// Authorization header value for IA's legacy S3 auth ("LOW" scheme,
  /// https only - see archive.org/developers/ias3.html).
  String get authorizationHeaderValue => 'LOW $accessKey:$secretKey';

  /// Masked form for UI display: only the first characters of the
  /// public-ish access key, never the secret.
  String get masked {
    if (accessKey.length <= 4) return '••••';
    return '${accessKey.substring(0, 4)}••••';
  }

  @override
  String toString() => 'IAS3Keys(access: $masked, secret: ••••)';

  @override
  bool operator ==(Object other) =>
      other is IAS3Keys &&
      other.accessKey == accessKey &&
      other.secretKey == secretKey;

  @override
  int get hashCode => Object.hash(accessKey, secretKey);
}

/// Minimal async key-value contract so the credential store is
/// unit-testable without platform channels (#95).
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production backend: Android keystore-backed secure storage.
class FlutterSecureStore implements SecureKeyValueStore {
  final FlutterSecureStorage _storage;

  FlutterSecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Stores the user's archive.org S3 keys in device secure storage.
///
/// Keys are never written to SharedPreferences, the database, or the
/// metadata cache, and never logged (#95).
class IACredentialsService {
  static const String _accessKeyKey = 'ia_s3_access_key';
  static const String _secretKeyKey = 'ia_s3_secret_key';

  final SecureKeyValueStore _store;

  IACredentialsService({SecureKeyValueStore? store})
    : _store = store ?? FlutterSecureStore();

  /// Whether keys have been configured on this device.
  Future<bool> hasKeys() async {
    final keys = await getKeys();
    return keys != null && keys.isValid;
  }

  /// The configured keys, or null when none are stored.
  Future<IAS3Keys?> getKeys() async {
    final access = await _store.read(_accessKeyKey);
    final secret = await _store.read(_secretKeyKey);
    if (access == null || access.isEmpty || secret == null || secret.isEmpty) {
      return null;
    }
    return IAS3Keys(accessKey: access, secretKey: secret);
  }

  /// Persists the keys to device secure storage.
  Future<void> saveKeys(IAS3Keys keys) async {
    await _store.write(_accessKeyKey, keys.accessKey);
    await _store.write(_secretKeyKey, keys.secretKey);
  }

  /// Removes the keys from this device.
  Future<void> clearKeys() async {
    await _store.delete(_accessKeyKey);
    await _store.delete(_secretKeyKey);
  }
}
