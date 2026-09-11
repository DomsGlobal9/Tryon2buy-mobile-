import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/utils/jwt_utils.dart';

String _jwt(Map<String, dynamic> claims) {
  String enc(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${enc({'alg': 'HS256', 'typ': 'JWT'})}.${enc(claims)}.signature';
}

void main() {
  final now = DateTime.utc(2026, 9, 10, 12);
  final exp = DateTime.utc(2026, 9, 17, 12);
  final token = _jwt({'vendorId': 'v1', 'role': 'merchant', 'exp': exp.millisecondsSinceEpoch ~/ 1000});

  test('reads the exp claim', () {
    expect(JwtUtils.expiryOf(token), exp);
  });

  test('is not expired before exp', () {
    expect(JwtUtils.isExpired(token, now: now), isFalse);
  });

  test('is expired after exp', () {
    expect(JwtUtils.isExpired(token, now: exp.add(const Duration(seconds: 1))), isTrue);
  });

  test('leeway treats a token about to expire as expired', () {
    expect(
      JwtUtils.isExpired(token, now: exp.subtract(const Duration(seconds: 10))),
      isTrue,
    );
    expect(
      JwtUtils.isExpired(token, now: exp.subtract(const Duration(minutes: 5))),
      isFalse,
    );
  });

  test('tokens without a readable exp are left to the server', () {
    expect(JwtUtils.expiryOf(_jwt({'vendorId': 'v1'})), isNull);
    expect(JwtUtils.isExpired(_jwt({'vendorId': 'v1'}), now: now), isFalse);
    expect(JwtUtils.expiryOf('vend-token'), isNull);
    expect(JwtUtils.isExpired('vend-token', now: now), isFalse);
    expect(JwtUtils.expiryOf('a.%%%.c'), isNull);
  });
}
