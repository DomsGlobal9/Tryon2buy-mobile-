import 'package:flutter/foundation.dart';

import '../network/auth_role.dart';
import '../storage/local_storage_service.dart';
import '../utils/jwt_utils.dart';

/// App-wide view of who is signed in.
///
/// The token and profile live in [LocalStorageService]; this wraps them in a
/// [ChangeNotifier] so screens that show account state (Profile, My Looks,
/// the merchant and B2B workspaces) rebuild — or leave — when a sign-in,
/// sign-out or token expiry happens anywhere else in the app.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  LocalStorageService? _storage;

  Future<LocalStorageService> _ensureStorage() async =>
      _storage ??= await LocalStorageService.getInstance();

  /// The handle to read from, without waiting.
  ///
  /// Falls back to the service's own warm instance, so a screen reached
  /// without anyone having called [refresh] first — the splash's direct jump
  /// into the B2B workspace, a deep link — still sees the real session
  /// instead of reporting "signed out" and hiding the merchant's own
  /// gallery and Save to Library.
  LocalStorageService? get _readable =>
      _storage ??= LocalStorageService.readyInstance;

  /// Takes a storage handle the caller has already resolved, and notifies.
  ///
  /// Synchronous on purpose. The splash calls this once it has committed to
  /// leaving: at that point its watchdog and its resume retry are both
  /// disarmed, so an `await` that never returns would strand the user on the
  /// splash forever. Nothing on that path may wait on the platform channel.
  void adopt(LocalStorageService storage) {
    _storage = storage;
    notifyListeners();
  }

  /// Drops the cached storage handle. Pair with
  /// [LocalStorageService.resetForTests].
  @visibleForTesting
  void resetForTests() => _storage = null;

  // ── Business account (merchant or B2B client) ──────────────────────────

  /// True while a token is stored and not past its `exp`.
  bool get isVendorSignedIn => _readable?.isVendorSignedIn ?? false;

  Map<String, dynamic>? get vendorProfile => _readable?.getVendorProfile();

  String? get vendorStoreName => _asText(
        vendorProfile?['storeName'] ??
            vendorProfile?['store_name'] ??
            vendorProfile?['companyName'] ??
            vendorProfile?['name'],
      );

  String? get vendorEmail => _asText(vendorProfile?['email']);

  String? get vendorCompanyName => _asText(vendorProfile?['companyName']);

  String? get vendorBusinessType => _asText(vendorProfile?['businessType']);

  String? get vendorMobileNumber => _asText(
        vendorProfile?['mobileNumber'] ??
            vendorProfile?['mobile_number'] ??
            vendorProfile?['phone'],
      );

  int get drapeCredits =>
      _asInt(vendorProfile?['drapeCredits'] ?? vendorProfile?['drape_credits']);

  int get userTryonCredits =>
      _asInt(vendorProfile?['userTryonCredits'] ?? vendorProfile?['user_tryon_credits']);

  int get bgChangeCredits =>
      _asInt(vendorProfile?['bgChangeCredits'] ?? vendorProfile?['bg_change_credits']);

  int get blouseChangeCredits =>
      _asInt(vendorProfile?['blouseChangeCredits'] ?? vendorProfile?['blouse_change_credits']);

  bool get isUnlimited =>
      vendorProfile?['isUnlimited'] == true || vendorProfile?['is_unlimited'] == true;

  bool get isB2bPortal => _readable?.isB2bPortal ?? false;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Reads the persisted session, discards an expired token, and notifies.
  /// Cheap to call repeatedly.
  Future<void> refresh() async {
    final storage = await _ensureStorage();
    await _dropIfExpired(storage);
    notifyListeners();
  }

  Future<void> signOutVendor() async {
    final storage = await _ensureStorage();
    await storage.logoutVendor();
    await storage.setPortalType('merchant');
    notifyListeners();
  }

  /// Drops the token the server just rejected with a 401, or that
  /// `ApiClient` found expired before sending.
  Future<void> invalidate(AuthRole role) async {
    if (role == AuthRole.none) return;
    final storage = await _ensureStorage();
    final token = storage.getVendorToken();
    if (token == null || token.isEmpty) return;
    await storage.logoutVendor();
    await storage.setPortalType('merchant');
    notifyListeners();
  }

  static Future<void> _dropIfExpired(LocalStorageService storage) async {
    final token = storage.getVendorToken();
    if (token == null || token.isEmpty || !JwtUtils.isExpired(token)) return;
    await storage.logoutVendor();
    await storage.setPortalType('merchant');
  }

  static String? _asText(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _asInt(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
