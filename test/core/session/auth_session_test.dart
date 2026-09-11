import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/core/network/auth_role.dart';
import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/storage/local_storage_service.dart';

/// An unsigned JWT with the given claims; the app never verifies signatures.
String fakeJwt(Map<String, dynamic> claims) {
  String enc(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256', 'typ': 'JWT'})}.${enc(claims)}.sig';
}

int _secondsFromNow(Duration d) =>
    DateTime.now().add(d).millisecondsSinceEpoch ~/ 1000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> seed(Map<String, Object> values) async {
    LocalStorageService.resetForTests();
    AuthSession.instance.resetForTests();
    SharedPreferences.setMockInitialValues(values);
  }

  test('exposes the vendor profile after refresh', () async {
    await seed({
      'vendor_token': 'vend-token',
      'vendor_profile': '{"id":"v1","storeName":"Silk Heritage","email":"v@example.com"}',
      'portal_type': 'b2b',
    });
    final session = AuthSession.instance;
    await session.refresh();

    expect(session.isVendorSignedIn, isTrue);
    expect(session.vendorStoreName, 'Silk Heritage');
    expect(session.vendorEmail, 'v@example.com');
    expect(session.isB2bPortal, isTrue);
  });

  test('signOutVendor clears the session, resets the portal and notifies', () async {
    await seed({'vendor_token': 'vend-token', 'portal_type': 'b2b'});
    final session = AuthSession.instance;
    await session.refresh();

    var notified = 0;
    void listener() => notified++;
    session.addListener(listener);
    await session.signOutVendor();
    session.removeListener(listener);

    expect(notified, 1);
    expect(session.isVendorSignedIn, isFalse);
    expect(session.isB2bPortal, isFalse);
  });

  test('invalidate(vendor) drops the token; invalidate(none) is a no-op', () async {
    await seed({'vendor_token': 'vend-token'});
    final session = AuthSession.instance;
    await session.refresh();

    await session.invalidate(AuthRole.none);
    expect(session.isVendorSignedIn, isTrue);

    await session.invalidate(AuthRole.vendor);
    expect(session.isVendorSignedIn, isFalse);
  });

  test('an expired JWT counts as signed out and is dropped on refresh', () async {
    await seed({
      'vendor_token': fakeJwt({
        'vendorId': 'v1',
        'role': 'merchant',
        'exp': _secondsFromNow(const Duration(hours: -1)),
      }),
      'portal_type': 'b2b',
    });
    final session = AuthSession.instance;
    await session.refresh();

    expect(session.isVendorSignedIn, isFalse);
    expect(session.isB2bPortal, isFalse);
    final storage = await LocalStorageService.getInstance();
    expect(storage.getVendorToken(), isNull);
  });

  test('a live JWT counts as signed in', () async {
    await seed({
      'vendor_token': fakeJwt({
        'vendorId': 'v1',
        'role': 'merchant',
        'exp': _secondsFromNow(const Duration(days: 6)),
      }),
    });
    final session = AuthSession.instance;
    await session.refresh();

    expect(session.isVendorSignedIn, isTrue);
  });

  test('reports the real session even when refresh was never called', () async {
    // A screen reached without anyone warming the session — the splash's
    // direct jump into the B2B workspace — used to read "signed out" and
    // hide the merchant's own gallery and Save to Library.
    await seed({
      'vendor_token': fakeJwt({
        'vendorId': 'v1',
        'role': 'merchant',
        'exp': _secondsFromNow(const Duration(days: 6)),
      }),
      'vendor_profile': '{"id":"v1","storeName":"Silk Heritage"}',
      'portal_type': 'b2b',
    });
    // Storage is warm, but AuthSession.refresh() has not run.
    await LocalStorageService.getInstance();

    expect(AuthSession.instance.isVendorSignedIn, isTrue);
    expect(AuthSession.instance.vendorStoreName, 'Silk Heritage');
    expect(AuthSession.instance.isB2bPortal, isTrue);
  });

  test('legacy customer keys are removed on init', () async {
    await seed({
      'customer_token': 'cust-token',
      'customer_profile': '{"id":"c1"}',
      'vendor_token': 'vend-token',
    });
    await LocalStorageService.getInstance();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('customer_token'), isFalse);
    expect(prefs.containsKey('customer_profile'), isFalse);
    expect(prefs.getString('vendor_token'), 'vend-token');
  });
}
