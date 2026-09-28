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

  /// The real windows are minutes long, so every test drives its own.
  Future<Map<String, dynamic>?> recover({
    Duration maxWait = const Duration(milliseconds: 150),
    Duration grace = const Duration(milliseconds: 40),
  }) =>
      ApiClient.recoverGeneration(
        'req-1',
        pollInterval: const Duration(milliseconds: 10),
        maxWait: maxWait,
        notFoundGrace: grace,
      );

  test('a completed generation is handed back', () async {
    ApiClient.client = MockClient((_) async => http.Response(
          '{"status":"COMPLETED","generation_id":"gen-9",'
          '"result_image_url":"https://cdn/result.jpg"}',
          200,
        ));

    final recovered = await recover();

    expect(recovered, isNotNull);
    expect(recovered!['generation_id'], 'gen-9');
    expect(recovered['result_image_url'], 'https://cdn/result.jpg');
  });

  test('a failed generation yields nothing to claim', () async {
    ApiClient.client = MockClient((_) async =>
        http.Response('{"status":"FAILED","generation_id":"gen-9"}', 200));

    expect(await recover(), isNull);
  });

  test('a request that never arrived is forgiven briefly, then given up on',
      () async {
    // The row is written early but not instantly, so the first polls can
    // genuinely 404 on work that is running. Aborting on the first one threw
    // away generations the server was still producing — and had charged for.
    var calls = 0;
    ApiClient.client = MockClient((_) async {
      calls++;
      return http.Response(
        '{"status":"UNKNOWN","error":"No generation found for that request id."}',
        404,
      );
    });

    final recovered = await recover();

    expect(recovered, isNull);
    expect(calls, greaterThan(1),
        reason: 'the first 404 is forgiven, not treated as proof of nothing');
  });

  test('a 404 after the work has been seen running does not abandon it',
      () async {
    // Once PROCESSING has come back the row exists, so a later 404 is an
    // anomaly — a replica lagging, a proxy hiccup — and never a reason to
    // walk away from a generation that has already been paid for.
    const notFound =
        '{"status":"UNKNOWN","error":"No generation found for that request id."}';
    const processing = '{"status":"PROCESSING"}';
    const done = '{"status":"COMPLETED","generation_id":"gen-9",'
        '"result_image_url":"https://cdn/result.jpg"}';

    var call = 0;
    ApiClient.client = MockClient((_) async {
      call++;
      return switch (call) {
        1 => http.Response(notFound, 404),
        2 => http.Response(processing, 200),
        // Well past the 40 ms grace by now; the old rule would stop here.
        3 || 4 || 5 || 6 || 7 => http.Response(notFound, 404),
        _ => http.Response(done, 200),
      };
    });

    final recovered = await recover(maxWait: const Duration(seconds: 2));

    expect(recovered, isNotNull);
    expect(recovered!['generation_id'], 'gen-9');
  });

  test('a generation still running is not mistaken for a failure', () async {
    ApiClient.client = MockClient(
      (_) async => http.Response('{"status":"PROCESSING"}', 200),
    );

    expect(await recover(), isNull);
  });
}
