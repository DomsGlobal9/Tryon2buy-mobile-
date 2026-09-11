import 'dart:convert';

/// Reads the standard `exp` claim out of a JWT without verifying it.
///
/// The app cannot verify the signature (the secret lives on the server) and
/// does not need to: the point is to stop *sending* a token the server would
/// reject, and to flip the UI to signed-out at that moment instead of one
/// request later. Backend tokens are HS256 with a 7-day `expiresIn`.
class JwtUtils {
  const JwtUtils._();

  /// The token's expiry in UTC, or null when it has no readable `exp`
  /// (opaque tokens, test fixtures, garbage). Null means "let the server
  /// decide".
  static DateTime? expiryOf(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload);
      final exp = claims is Map ? claims['exp'] : null;
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
      }
    } catch (_) {
      // Not a JWT we understand.
    }
    return null;
  }

  /// True when the token is past (or within [leeway] of) its expiry.
  static bool isExpired(
    String token, {
    Duration leeway = const Duration(seconds: 30),
    DateTime? now,
  }) {
    final exp = expiryOf(token);
    if (exp == null) return false;
    final at = (now ?? DateTime.now()).toUtc();
    return !at.isBefore(exp.subtract(leeway));
  }
}
