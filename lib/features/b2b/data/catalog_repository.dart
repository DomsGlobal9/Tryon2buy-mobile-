import 'dart:io';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import 'models/catalog_product.dart';

/// Data layer for the B2B catalog — product digitization, listing, and deletion.
///
/// Every method follows the same `ApiClient.verb → ApiResponse` contract used
/// by [VendorRepository] and [LibraryRepository]. All routes are vendor-scoped
/// (the JWT carries the vendor id), so ownership checks happen server-side.
class CatalogRepository {
  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetches the vendor's business profile, which includes the list of
  /// allowed garment categories (set during onboarding). Returns the raw
  /// map so the caller can pull whatever fields it needs.
  Future<ApiResponse<Map<String, dynamic>>> fetchVendorProfile() async {
    return ApiClient.get<Map<String, dynamic>>(
      ApiEndpoints.vendorProfile,
      role: AuthRole.vendor,
    );
  }

  /// Fetches the full account profile from the auth service (email, company
  /// name, business type, phone). Used by the business-profile bottom sheet.
  Future<ApiResponse<Map<String, dynamic>>> fetchBusinessProfile() async {
    return ApiClient.get<Map<String, dynamic>>(
      ApiEndpoints.authVendorProfile,
      role: AuthRole.vendor,
    );
  }

  /// Lists all products this vendor has digitized.
  Future<ApiResponse<List<CatalogProduct>>> fetchProducts() async {
    final response = await ApiClient.get<List<dynamic>>(
      ApiEndpoints.catalogProducts,
      role: AuthRole.vendor,
    );

    if (response.success && response.data != null) {
      final products = response.data!
          .whereType<Map<String, dynamic>>()
          .map(CatalogProduct.fromJson)
          .toList();
      return ApiResponse.success(products);
    }

    return ApiResponse.failure(
      response.error ?? 'Failed to load catalog',
      statusCode: response.statusCode,
    );
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Uploads a garment image to Supabase. Delegates to the same
  /// `POST /api/tryon/upload?folder=garments` that [VendorRepository] uses.
  Future<ApiResponse<String>> uploadGarmentImage(File file) async {
    final response = await ApiClient.postMultipart<Map<String, dynamic>>(
      ApiEndpoints.uploadImage,
      file: file,
      queryParams: {'folder': 'garments'},
      role: AuthRole.vendor,
    );

    if (response.success && response.data != null) {
      final url = response.data!['url'] as String?;
      if (url != null) return ApiResponse.success(url);
    }

    return ApiResponse.failure(response.error ?? 'Failed to upload image');
  }

  /// Generates a catalog shoot (phase-1 drape) for the given garment slots.
  ///
  /// [garmentSlots] is the slot→URL JSON map (e.g. `{'saree': '…', 'blouse': '…'}`).
  /// [modelImageUrl] is the studio model the vendor chose.
  /// Returns the raw response map which includes `result_image_url` and
  /// `generation_id`.
  /// The server picks the studio model itself (at random, per category) and
  /// only reads `garment_image_url`, `category` and `dupatta_style_url` —
  /// exactly what the website's `VendorUpload.jsx` sends.
  Future<ApiResponse<Map<String, dynamic>>> generateCatalogPreview({
    required String garmentSlots,
    required String category,
    String? dupattaStyleUrl,
  }) {
    return ApiClient.post<Map<String, dynamic>>(
      ApiEndpoints.catalogGenerate,
      body: {
        'garment_image_url': garmentSlots,
        'category': category,
        if (dupattaStyleUrl != null) 'dupatta_style_url': dupattaStyleUrl,
      },
      role: AuthRole.vendor,
      // Multi-piece drapes run past the ordinary timeout; giving up early
      // orphans the preview asset the server has already started.
      timeout: ApiClient.generationTimeout,
    );
  }

  /// Saves a generation as a catalog product. Requires the id produced by
  /// [generateCatalogPreview]. Note the server wants snake_case
  /// `generation_id` here (unlike `save-to-library`); the previous camelCase
  /// key made every save fail with 400.
  Future<ApiResponse<Map<String, dynamic>>> saveToCatalog({
    required String generationId,
    required String title,
    required String category,
    String? description,
    String? sku,
  }) {
    return ApiClient.post<Map<String, dynamic>>(
      ApiEndpoints.catalogSave,
      body: {
        'generation_id': generationId,
        'title': title,
        'category': category,
        if (description != null) 'description': description,
        if (sku != null) 'sku': sku,
      },
      role: AuthRole.vendor,
    );
  }

  /// Discards a previewed generation without saving it as a product.
  Future<ApiResponse<bool>> discardPreview(String generationId) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      ApiEndpoints.catalogDiscard,
      body: {'generation_id': generationId},
      role: AuthRole.vendor,
    );

    if (response.success) return ApiResponse.success(true);
    return ApiResponse.failure(
      response.error ?? 'Failed to discard preview',
      statusCode: response.statusCode,
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Deletes a product from the catalog. Ownership is enforced server-side.
  Future<ApiResponse<bool>> deleteProduct(String productId) async {
    final response = await ApiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.catalogProductDelete(productId),
      role: AuthRole.vendor,
    );

    if (response.success) return ApiResponse.success(true);
    return ApiResponse.failure(
      response.error ?? 'Failed to delete product',
      statusCode: response.statusCode,
    );
  }

  // ── Profile Update ────────────────────────────────────────────────────────

  /// Updates the vendor's business profile. `PUT /api/auth/vendor/profile`
  /// with the three fields the website's profile modal edits.
  Future<ApiResponse<Map<String, dynamic>>> updateBusinessProfile({
    required String companyName,
    required String businessType,
    required String mobileNumber,
  }) {
    return ApiClient.put<Map<String, dynamic>>(
      ApiEndpoints.authVendorProfile,
      body: {
        'companyName': companyName,
        'businessType': businessType,
        'mobileNumber': mobileNumber,
      },
      role: AuthRole.vendor,
    );
  }
}
