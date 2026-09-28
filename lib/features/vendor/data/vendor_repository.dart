import 'dart:io';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/local_storage_service.dart';

class VendorRepository {
  Future<ApiResponse<String>> uploadGarmentImage(
    File file, {
    String folder = ApiEndpoints.folderGarments,
  }) async {
    final response = await ApiClient.postMultipart<Map<String, dynamic>>(
      ApiEndpoints.uploadImage,
      file: file,
      queryParams: {'folder': folder},
      role: AuthRole.vendor,
    );

    if (response.success && response.data != null) {
      final url = response.data!['url'] as String?;
      if (url != null) {
        return ApiResponse.success(url);
      }
    }

    return ApiResponse.failure(response.error ?? 'Failed to upload image');
  }

  /// Drapes the uploaded garment on a studio model — the vendor's catalog shoot.
  ///
  /// Mirrors the web workspace: every fabric piece is uploaded first, then the
  /// slot→URL map is sent as a JSON *string* in `garment_image_url`. The server
  /// parses it and drapes each piece (`saree`, `blouse`, `full`, …); a plain
  /// URL string also works for single-piece garments.
  ///
  /// `human_image_url` is the chosen studio model's image, which is what makes
  /// this a phase-1 vendor drape rather than a customer try-on.
  Future<ApiResponse<Map<String, dynamic>>> generateVendorDrape({
    required String garmentImageUrl,
    required String modelImageUrl,
    String? category,
    String? garmentId,
    String? dupattaStyleUrl,
  }) async {
    // Recorded against the row before the model runs, so a drape whose
    // response is lost can still be claimed. A merchant's drape credit is
    // spent either way, and an unclaimed one is an orphan nobody can reach.
    final clientRequestId = ApiClient.newRequestId();

    // The workspace is open to guests as well as merchants. A guest's free
    // tries are counted against this install; without the id the server
    // counts by network address, so one boutique's wifi shares a single
    // allowance. A signed-in merchant is charged to the account instead.
    final token = await ApiClient.tokenFor(AuthRole.vendor);
    final guestDeviceId = (token == null || token.isEmpty)
        ? await (await LocalStorageService.getInstance())
            .getOrCreateGuestDeviceId()
        : null;

    final response = await ApiClient.post<Map<String, dynamic>>(
      ApiEndpoints.generateTryon,
      body: {
        'mode': 'with_garment',
        'garment_image_url': garmentImageUrl,
        'human_image_url': modelImageUrl,
        'target_folder': ApiEndpoints.targetVendorDrapes,
        'client_request_id': clientRequestId,
        'category': ?category,
        'garment_id': ?garmentId,
        'guest_device_id': ?guestDeviceId,
        // Sent even when null: the website always includes the key.
        'dupatta_style_url': dupattaStyleUrl,
      },
      // A signed-in merchant's token; without one the server treats the call
      // as a guest (10 free tries per IP).
      role: AuthRole.vendor,
      // The credit is debited before the pipeline runs; never give up early.
      timeout: ApiClient.generationTimeout,
    );

    // A credit gate or a rejected token is a real answer; only a lost
    // connection is worth chasing.
    if (response.success || response.statusCode != null) return response;

    final recovered = await ApiClient.recoverGeneration(clientRequestId);
    if (recovered != null) return ApiResponse.success(recovered);
    return response;
  }

  /// Attaches a finished generation to this vendor's library.
  /// `POST /api/tryon/save-to-library` — vendor token required.
  Future<ApiResponse<bool>> saveGenerationToLibrary(String generationId) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      ApiEndpoints.saveToLibrary,
      body: {'generationId': generationId},
      role: AuthRole.vendor,
    );

    if (response.success) return ApiResponse.success(true);
    return ApiResponse.failure(
      response.error ?? 'Failed to save to library',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<List<dynamic>>> fetchVendorGenerations() async {
    final response = await ApiClient.get<List<dynamic>>(
      ApiEndpoints.vendorGenerations,
      role: AuthRole.vendor,
    );
    return response;
  }

  /// Deletes one of the vendor's own generations.
  /// `DELETE /api/tryon/vendor/generations/:id` — 404s if the row belongs to
  /// another vendor, so ownership is enforced server-side.
  Future<ApiResponse<bool>> deleteVendorGeneration(String id) async {
    final response = await ApiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.deleteVendorGeneration(id),
      role: AuthRole.vendor,
    );

    if (response.success) {
      return ApiResponse.success(true);
    }
    return ApiResponse.failure(response.error ?? 'Failed to delete generation');
  }
}
