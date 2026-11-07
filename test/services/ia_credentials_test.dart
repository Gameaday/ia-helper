import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/ia_credentials_service.dart';

class _FakeStore implements SecureKeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

void main() {
  group('IAS3Keys', () {
    const keys = IAS3Keys(accessKey: 'ACCESS1234', secretKey: 'SECRET456');

    test('toString never contains the secret', () {
      expect(keys.toString(), isNot(contains('SECRET456')));
      expect(keys.toString(), isNot(contains('ACCESS1234')));
    });

    test('masked exposes only the access-key prefix', () {
      expect(keys.masked, isNot(contains('SECRET')));
      expect(keys.masked, 'ACCE••••');
      expect(const IAS3Keys(accessKey: 'AB', secretKey: 'S').masked, '••••');
    });

    test('authorization header uses the LOW scheme', () {
      expect(keys.authorizationHeaderValue, 'LOW ACCESS1234:SECRET456');
    });

    test('validity requires both halves', () {
      expect(keys.isValid, isTrue);
      expect(const IAS3Keys(accessKey: '', secretKey: 'x').isValid, isFalse);
      expect(const IAS3Keys(accessKey: 'x', secretKey: '').isValid, isFalse);
    });

    test('equality covers both halves', () {
      expect(keys, const IAS3Keys(accessKey: 'ACCESS1234', secretKey: 'SECRET456'));
      expect(
        keys,
        isNot(const IAS3Keys(accessKey: 'ACCESS1234', secretKey: 'other')),
      );
    });
  });

  group('IACredentialsService', () {
    test('round-trips keys through the store and clears them', () async {
      final store = _FakeStore();
      final service = IACredentialsService(store: store);

      expect(await service.hasKeys(), isFalse);
      expect(await service.getKeys(), isNull);

      await service.saveKeys(const IAS3Keys(accessKey: 'A1', secretKey: 'S1'));
      expect(await service.hasKeys(), isTrue);
      expect(
        await service.getKeys(),
        const IAS3Keys(accessKey: 'A1', secretKey: 'S1'),
      );

      await service.clearKeys();
      expect(await service.hasKeys(), isFalse);
      expect(await service.getKeys(), isNull);
    });

    test('partial stored state is treated as no keys', () async {
      final store = _FakeStore();
      await store.write('ia_s3_access_key', 'A1');
      final service = IACredentialsService(store: store);
      expect(await service.getKeys(), isNull);
      expect(await service.hasKeys(), isFalse);
    });

    test('the default store is the secure-storage adapter', () {
      expect(FlutterSecureStore(), isA<SecureKeyValueStore>());
    });
  });
}
