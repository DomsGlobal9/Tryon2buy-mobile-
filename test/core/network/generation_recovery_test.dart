import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/core/network/api_client.dart';
import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/storage/local_storage_service.dart';

/// Generation is slow and synchronous, so the connection carrying the result
/// is the least reliable part of the flow, and the credit is already spent
/// when it drops. These cover the claim path that hands the work over.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocalStorageService.resetForTests();
    AuthSession.instance.resetForTests();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ApiClient.client = http.Client();
  });

  test('a request id is unique per attempt', () {
    final ids = List.generate(50, (_) => ApiClient.newRequestId()).toSet();
    expect(ids, hasLength(50));
    for (final id in ids) {
      expect(id.length, lessThan(200));
      expect(RegExp(r'^[0-9a-f-]+$').hasMatch(id), isTrue, reason: id);
    }
  });

  test('a completed generation is handed back', () async {
    ApiClient.client = MockClient((_) async => http.Response(
          '{"status":"COMPLETED","generation_id":"gen-9",'
          '"result_image_url":"https://cdn/result.jpg"}',
          200,
        ));

    final recovered =
        await ApiClient.recoverGeneration('req-1', attempts: 1);

    expect(recovered, isNotNull);
    expect(recovered!['generation_id'], 'gen-9');
    expect(recovered['result_image_url'], 'https://cdn/result.jpg');
  });

  test('a failed generation yields nothing to claim', () async {
    ApiClient.client = MockClient((_) async =>
        http.Response('{"status":"FAILED","generation_id":"gen-9"}', 200));

    expect(await ApiClient.recoverGeneration('req-1', attempts: 1), isNull);
  });

  test('a request that never arrived stops the polling at once', () async {
    var calls = 0;
    ApiClient.client = MockClient((_) async {
      calls++;
      return http.Response(
        '{"status":"UNKNOWN","error":"No generation found for that request id."}',
        404,
      );
    });

    final recovered =
        await ApiClient.recoverGeneration('req-1', attempts: 5);

    expect(recovered, isNull);
    expect(calls, 1, reason: 'a 404 means nothing was started or charged');
  });

  test('a generation still running is not mistaken for a failure', () async {
    ApiClient.client = MockClient(
      (_) async => http.Response('{"status":"PROCESSING"}', 200),
    );

    expect(await ApiClient.recoverGeneration('req-1', attempts: 1), isNull);
  });
}
