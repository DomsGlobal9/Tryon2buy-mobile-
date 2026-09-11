import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/storage/local_storage_service.dart';
import 'models/user_model.dart';

/// Sign-in flows for the two business account types. Shoppers are guests and
/// never authenticate, as on the website.
///
/// Every successful call persists the token and profile, then pokes
/// [AuthSession] so account-aware screens rebuild.
class AuthRepository {
  Future<ApiResponse<UserModel>> loginVendor({
    required String email,
    required String password,
  }) {
    return _vendorAuth(
      ApiEndpoints.vendorLogin,
      // The server enforces the portal: a B2B account cannot enter the
      // merchant studio and vice versa. Same as the website's `VendorAuth`.
      body: {'email': email, 'password': password, 'expectedRole': 'merchant'},
      role: 'merchant',
      portalType: 'merchant',
      failureMessage: 'Failed to login vendor',
    );
  }

  Future<ApiResponse<UserModel>> registerVendor({
    required String email,
    required String password,
    String? name,
    String? storeName,
  }) {
    return _vendorAuth(
      ApiEndpoints.vendorRegister,
      body: {
        'email': email,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
        if (storeName != null && storeName.isNotEmpty) 'storeName': storeName,
      },
      role: 'vendor',
      portalType: 'merchant',
      failureMessage: 'Failed to register vendor',
    );
  }

  /// B2B client login — same token flow as [loginVendor], but sends
  /// `expectedRole: 'b2b_client'` so the server rejects non-B2B accounts
  /// with 403, and records the portal type so the app opens the right
  /// workspace next launch.
  Future<ApiResponse<UserModel>> loginB2bClient({
    required String email,
    required String password,
  }) {
    return _vendorAuth(
      ApiEndpoints.vendorLogin,
      body: {
        'email': email,
        'password': password,
        'expectedRole': 'b2b_client',
      },
      role: 'b2b_client',
      portalType: 'b2b',
      failureMessage: 'Access denied.',
    );
  }

  Future<void> enableGuestMode() async {
    final storage = await LocalStorageService.getInstance();
    await storage.setGuestMode(true);
  }

  // ── Shared business-side flow ──────────────────────────────────────────

  Future<ApiResponse<UserModel>> _vendorAuth(
    String url, {
    required Map<String, dynamic> body,
    required String role,
    required String portalType,
    required String failureMessage,
  }) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      url,
      body: body,
      role: AuthRole.none,
    );

    final data = response.data;
    if (!response.success || data == null) {
      return ApiResponse.failure(
        response.error ?? failureMessage,
        statusCode: response.statusCode,
      );
    }

    final token = data['token'] as String?;
    final profile = data['vendor'] as Map<String, dynamic>?;
    if (token == null || profile == null) {
      return ApiResponse.failure('Unexpected response from server.');
    }

    final storage = await LocalStorageService.getInstance();
    await storage.setVendorToken(token);
    await storage.setVendorProfile(profile);
    await storage.setPortalType(portalType);
    await storage.setGuestMode(false);
    await AuthSession.instance.refresh();

    return ApiResponse.success(UserModel.fromJson(profile, role: role));
  }
}
