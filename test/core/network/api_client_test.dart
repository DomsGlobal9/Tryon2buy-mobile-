import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/core/network/api_client.dart';
import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/storage/local_storage_service.dart';

String _jwt(Map<String, dynamic> claims) {
  String enc(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc(claims)}.sig';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> seed(Map<String, Object> values) async {
    LocalStorageService.resetForTests();
    AuthSession.instance.resetForTests();
    SharedPreferences.setMockInitialValues(values);
  }

  tearDown(() {
    ApiClient.client = http.Client();
  });

  test('a guest-limit 401 is a quota, not a dead token', () async {
    await seed({'vendor_token': 'vend-token'});
    ApiClient.client = MockClient((_) async => http.Response(
          '{"error":"GUEST_LIMIT_REACHED","message":"Login as Vendor for more credits."}',
          401,
        ));

    final res = await ApiClient.post<Map<String, dynamic>>(
      'https://example.test/api/tryon/generate',
      body: const {},
    );

    expect(res.success, isFalse);
    expect(res.isGuestLimitReached, isTrue);
    expect(res.error, 'Login as Vendor for more credits.');
    final storage = await LocalStorageService.getInstance();
    expect(storage.getVendorToken(), 'vend-token');
  });

  test('an ordinary 401 drops the stored token', () async {
    await seed({'vendor_token': 'vend-token'});
    ApiClient.client = MockClient(
      (_) async => http.Response('{"error":"Invalid or expired token."}', 401),
    );

    final res = await ApiClient.get<dynamic>(
      'https://example.test/api/tryon/vendor/generations',
      role: AuthRole.vendor,
    );

    expect(res.statusCode, 401);
    final storage = await LocalStorageService.getInstance();
    expect(storage.getVendorToken(), isNull);
  });

  test('an expired JWT is never sent and is dropped', () async {
    final expired = _jwt({
      'vendorId': 'v1',
      'role': 'merchant',
      'exp': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
    });
    await seed({'vendor_token': expired});
    String? sentAuth;
    ApiClient.client = MockClient((req) async {
      sentAuth = req.headers['Authorization'];
      return http.Response('{"ok":true}', 200);
    });

    final res = await ApiClient.get<Map<String, dynamic>>(
      'https://example.test/x',
      role: AuthRole.vendor,
    );

    expect(res.success, isTrue);
    expect(sentAuth, isNull);
    final storage = await LocalStorageService.getInstance();
    expect(storage.getVendorToken(), isNull);
  });

  test('a live token is sent as a bearer', () async {
    await seed({'vendor_token': 'vend-token'});
    String? sentAuth;
    ApiClient.client = MockClient((req) async {
      sentAuth = req.headers['Authorization'];
      return http.Response('[]', 200);
    });

    await ApiClient.get<List<dynamic>>('https://example.test/x', role: AuthRole.vendor);

    expect(sentAuth, 'Bearer vend-token');
  });

  test('a 200 with the wrong shape is a failure, not a cast error', () async {
    await seed({});
    ApiClient.client = MockClient((_) async => http.Response('<html>proxy</html>', 200));

    final res = await ApiClient.get<Map<String, dynamic>>('https://example.test/x');

    expect(res.success, isFalse);
    expect(res.error, 'The server sent an unexpected response.');
  });
}
