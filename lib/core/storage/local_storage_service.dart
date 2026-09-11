import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/jwt_utils.dart';

class LocalStorageService {
  /// Forgets the cached preferences so a test can start from fresh mock
  /// values. Never called by app code.
  @visibleForTesting
  static void resetForTests() {
    _instance = null;
    _preferences = null;
    _initFuture = null;
  }

  static const String _keyVendorToken = 'vendor_token';
  static const String _keyVendorProfile = 'vendor_profile';
  static const String _keyGuestMode = 'guest_mode';

  /// Keys from the abandoned shopper-account model. Removed on first launch
  /// after the upgrade so an old install carries no stale customer token.
  static const List<String> _legacyKeys = ['customer_token', 'customer_profile'];

  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  /// The in-flight initialisation, cached so concurrent callers share one
  /// disk read instead of each starting their own. `main()` warms this in the
  /// background while the splash awaits the same future with a timeout.
  static Future<LocalStorageService>? _initFuture;

  /// The service only if its disk read has already finished, else null.
  /// For callers that must not wait (the splash's watchdog path).
  static LocalStorageService? get readyInstance =>
      _preferences != null ? _instance : null;

  static Future<LocalStorageService> getInstance() {
    // Already warm — hand it back without an async gap.
    final ready = _instance;
    if (ready != null && _preferences != null) {
      return Future<LocalStorageService>.value(ready);
    }
    return _initFuture ??= _init();
  }

  static Future<LocalStorageService> _init() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      for (final key in _legacyKeys) {
        if (_preferences!.containsKey(key)) await _preferences!.remove(key);
      }
    } catch (_) {
      // Leave `_preferences` null and let the next call retry. Every accessor
      // null-guards, so the app runs (signed-out) rather than failing to start.
      _initFuture = null;
    }
    return _instance ??= LocalStorageService();
  }

  // ── Business token ─────────────────────────────────────────────────────
  // One kind of account: the merchant or B2B client. Shoppers are guests.

  Future<bool> setVendorToken(String token) async {
    return await _preferences?.setString(_keyVendorToken, token) ?? false;
  }

  /// The raw stored token, expired or not. Prefer [isVendorSignedIn] for
  /// decisions; `ApiClient` never sends an expired one.
  String? getVendorToken() {
    return _preferences?.getString(_keyVendorToken);
  }

  /// True while a business token is stored *and* not past its `exp` claim.
  /// The backend issues 7-day tokens with no refresh, so a merchant who
  /// reopens the app on day 8 is signed out here, not one request later.
  bool get isVendorSignedIn {
    final token = getVendorToken();
    return token != null && token.isNotEmpty && !JwtUtils.isExpired(token);
  }

  // ── Profile ────────────────────────────────────────────────────────────
  // The web app keeps the same object under `vendor_data`. We need at least
  // the id: it is the only way to build a merchant's public storefront link,
  // and the token itself is opaque to the client.

  Future<bool> setVendorProfile(Map<String, dynamic> profile) async {
    return await _preferences?.setString(
          _keyVendorProfile,
          jsonEncode(profile),
        ) ??
        false;
  }

  Map<String, dynamic>? getVendorProfile() {
    final raw = _preferences?.getString(_keyVendorProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? getVendorId() => getVendorProfile()?['id'] as String?;

  // ── Guest mode ─────────────────────────────────────────────────────────
  // Persisted: once a shopper chose "Continue as guest" the app opens on the
  // home shell at every launch, until they sign in as a business or exit
  // guest mode. Only a fresh install (or a sign-out that clears it) sees the
  // welcome screen again.

  Future<bool> setGuestMode(bool isGuest) async {
    return await _preferences?.setBool(_keyGuestMode, isGuest) ?? false;
  }

  bool isGuestMode() {
    return _preferences?.getBool(_keyGuestMode) ?? false;
  }

  // ── Portal Type ─────────────────────────────────────────────────────────
  // The web app stores `portal_type: 'b2b' | 'merchant'` in localStorage.
  // This controls where the Merchant tab routes on launch.
  static const String _keyPortalType = 'portal_type';

  Future<bool> setPortalType(String type) async =>
      await _preferences?.setString(_keyPortalType, type) ?? false;

  String getPortalType() =>
      _preferences?.getString(_keyPortalType) ?? 'merchant';

  bool get isB2bPortal => getPortalType() == 'b2b';

  // ── Recent searches ────────────────────────────────────────────────────
  static const String _keyRecentSearches = 'recent_searches';
  static const int _maxRecentSearches = 8;

  List<String> getRecentSearches() =>
      _preferences?.getStringList(_keyRecentSearches) ?? const [];

  /// Moves [query] to the front of the list, de-duplicated, capped.
  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final existing = getRecentSearches()
        .where((q) => q.toLowerCase() != trimmed.toLowerCase())
        .take(_maxRecentSearches - 1);
    await _preferences
        ?.setStringList(_keyRecentSearches, [trimmed, ...existing]);
  }

  Future<void> clearRecentSearches() async {
    await _preferences?.remove(_keyRecentSearches);
  }

  // ── Sign out ───────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    await _preferences?.clear();
  }

  Future<void> logoutVendor() async {
    await _preferences?.remove(_keyVendorToken);
    await _preferences?.remove(_keyVendorProfile);
  }
}
