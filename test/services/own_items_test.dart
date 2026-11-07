import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:internet_archive_helper/services/ia_credentials_service.dart';
import 'package:internet_archive_helper/services/own_items_service.dart';

const String _bucketXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult>
  <Owner><ID>me</ID><DisplayName>Me</DisplayName></Owner>
  <Buckets>
    <Bucket><Name>zzz-2026</Name><CreationDate>2026-01-02T03:04:05.000Z</CreationDate></Bucket>
    <Bucket><Name>alpha-item</Name><CreationDate>2025-05-06T07:08:09.000Z</CreationDate></Bucket>
    <Bucket><Name>beta &amp; gamma</Name><CreationDate>not-a-date</CreationDate></Bucket>
  </Buckets>
</ListAllMyBucketsResult>
''';

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

OwnItemsService _serviceWithKeys(http.Client client) {
  final store = _FakeStore();
  store.data['ia_s3_access_key'] = 'ACCESS1234';
  store.data['ia_s3_secret_key'] = 'SECRET456';
  return OwnItemsService(
    client: client,
    credentials: IACredentialsService(store: store),
  );
}

void main() {
  group('parseBucketList', () {
    test('parses names, unescapes XML entities, tolerates bad dates', () {
      final items = OwnItemsService.parseBucketList(_bucketXml);
      expect(items.length, 3);
      expect(items.map((i) => i.identifier), contains('beta & gamma'));
      // Invalid CreationDate must not break parsing.
      expect(
        items.firstWhere((i) => i.identifier == 'beta & gamma').creationDate,
        isNull,
      );
    });

    test('parses creation dates', () {
      final items = OwnItemsService.parseBucketList(
        '<Bucket><Name>x</Name>'
        '<CreationDate>2026-01-02T03:04:05.000Z</CreationDate></Bucket>',
      );
      expect(items.single.creationDate, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });

    test('skips buckets without a name and handles empty input', () {
      expect(OwnItemsService.parseBucketList(''), isEmpty);
      expect(
        OwnItemsService.parseBucketList(
          '<Buckets><Bucket>'
          '<CreationDate>2020-01-01T00:00:00.000Z</CreationDate>'
          '</Bucket></Buckets>',
        ),
        isEmpty,
      );
    });
  });

  group('listOwnItems', () {
    test('sends LOW auth and returns sorted items', () async {
      String? auth;
      final client = MockClient((request) async {
        auth = request.headers['Authorization'];
        return http.Response(_bucketXml, 200);
      });
      final service = _serviceWithKeys(client);
      addTearDown(service.dispose);

      final items = await service.listOwnItems();

      expect(auth, 'LOW ACCESS1234:SECRET456');
      expect(items.length, 3);
      expect(items.first.identifier, 'alpha-item');
      expect(items.last.identifier, 'zzz-2026');
    });

    test('403 maps to an auth error that never leaks the keys', () async {
      final client = MockClient(
        (request) async => http.Response('Forbidden', 403),
      );
      final service = _serviceWithKeys(client);
      addTearDown(service.dispose);

      await expectLater(
        service.listOwnItems(),
        throwsA(
          isA<IAS3AuthException>().having(
            (e) => e.message,
            'message',
            allOf(isNot(contains('SECRET456')), isNot(contains('ACCESS1234'))),
          ),
        ),
      );
    });

    test('missing keys prompt setup instead of making a request', () async {
      final client = MockClient(
        (request) async => fail('no request should be made without keys'),
      );
      final service = OwnItemsService(
        client: client,
        credentials: IACredentialsService(store: _FakeStore()),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.listOwnItems(),
        throwsA(isA<IAS3AuthException>()),
      );
    });
  });

  group('updateItemMetadata', () {
    test('posts urlencoded fields to /metadata/{id} and reports success', () async {
      String? url;
      String? contentType;
      Map<String, String> body = {};
      final client = MockClient((request) async {
        url = request.url.toString();
        contentType = request.headers['Content-Type'];
        body = Uri.splitQueryString(request.body);
        return http.Response('{"success": true, "task_id": "t1"}', 200);
      });
      final service = _serviceWithKeys(client);
      addTearDown(service.dispose);

      final ok = await service.updateItemMetadata(
        'my-item',
        title: 'New Title',
        description: 'Better description',
        subject: 'history, primary sources',
      );

      expect(ok, isTrue);
      expect(url, 'https://archive.org/metadata/my-item');
      expect(contentType, 'application/x-www-form-urlencoded');
      expect(body['title'], 'New Title');
      expect(body['description'], 'Better description');
      expect(body['subject'], 'history, primary sources');
    });

    test('omits empty subject and untouched fields', () async {
      Map<String, String> body = {};
      final client = MockClient((request) async {
        body = Uri.splitQueryString(request.body);
        return http.Response('{"success": true}', 200);
      });
      final service = _serviceWithKeys(client);
      addTearDown(service.dispose);

      final ok = await service.updateItemMetadata('my-item', title: 'T');

      expect(ok, isTrue);
      expect(body.keys.toList(), ['title']);
    });

    test('reports API rejection without the success flag', () async {
      final client = MockClient(
        (request) async =>
            http.Response('{"success": false, "error": "nope"}', 200),
      );
      final service = _serviceWithKeys(client);
      addTearDown(service.dispose);

      expect(
        await service.updateItemMetadata('my-item', title: 'T'),
        isFalse,
      );
    });

    test('401 maps to an auth error that never leaks the keys', () async {
      final client = MockClient((request) async => http.Response('', 401));
      final service = _serviceWithKeys(client);
      addTearDown(service.dispose);

      await expectLater(
        service.updateItemMetadata('my-item', title: 'T'),
        throwsA(
          isA<IAS3AuthException>().having(
            (e) => e.message,
            'message',
            allOf(isNot(contains('SECRET456')), isNot(contains('ACCESS1234'))),
          ),
        ),
      );
    });

    test('returns false when there is nothing to change', () async {
      final client = MockClient(
        (request) async => fail('no request should be made for no changes'),
      );
      final service = _serviceWithKeys(client);
      addTearDown(service.dispose);

      expect(await service.updateItemMetadata('my-item'), isFalse);
    });
  });
}
