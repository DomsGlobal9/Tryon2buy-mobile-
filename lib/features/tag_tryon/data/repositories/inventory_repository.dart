import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/scanned_garment.dart';

/// Interacts with Scaleezy Inventory backend for physical in-store scanned tags.
///
/// Lookups and try-on generations for physical tags run through Scaleezy Inventory
/// because the garment data and shop monthly quota are tracked and metered there.
class InventoryRepository {
  final http.Client _client;

  InventoryRepository({http.Client? client})
      : _client = client ?? ApiClient.client;

  /// Looks up garment details from Scaleezy Inventory using the scanned tag info.
  Future<ApiResponse<ScannedGarment>> fetchGarment({
    required String clientId,
    required String productCode,
    String? variant,
  }) async {
    final uri = Uri.parse(
      ApiEndpoints.inventoryGarment(clientId, productCode, variant: variant),
    );

    try {
      final response = await _client
          .get(uri)
          .timeout(ApiClient.timeoutDuration);

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body?['data'] as Map<String, dynamic>?;
        if (data == null) {
          return ApiResponse.failure('Garment data not found.');
        }
        return ApiResponse.success(ScannedGarment.fromJson(data));
      }

      final msg = body?['message'] as String? ??
          'That code does not match anything we can try on.';
      return ApiResponse.failure(msg, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure(ApiClient.friendlyError(e));
    }
  }

  /// Generates virtual try-on through Scaleezy Inventory, metered against the shop.
  Future<ApiResponse<String>> generateTryon({
    required String clientId,
    required String productCode,
    required String humanImageUrl,
    required String garmentImageUrl,
    String? category,
    String? variant,
  }) async {
    final uri = Uri.parse(
      ApiEndpoints.inventoryGenerate(clientId, productCode),
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'human_image_url': humanImageUrl,
              'garment_image_url': garmentImageUrl,
              if (category != null && category.isNotEmpty) 'category': category,
              if (variant != null && variant.isNotEmpty) 'variant': variant,
            }),
          )
          .timeout(const Duration(seconds: 120));

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 401 || response.statusCode == 403) {
        final err = (body?['message'] ?? body?['error']) as String?;
        if (err == 'GUEST_LIMIT_REACHED') {
          return ApiResponse.failure(
            'Guest try-on limit reached. Please sign in or contact the shop.',
            statusCode: response.statusCode,
          );
        }
        if (err == 'INSUFFICIENT_CREDITS') {
          return ApiResponse.failure(
            'The shop has reached its try-on allowance for this month.',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.failure(
          err ?? 'Access denied for try-on generation.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body?['data'] as Map<String, dynamic>?;
        final resultUrl = (data?['resultImageUrl'] ?? body?['result_image_url']) as String?;
        if (resultUrl != null && resultUrl.isNotEmpty) {
          return ApiResponse.success(resultUrl);
        }
        return ApiResponse.failure('No generated image received from server.');
      }

      final errorMsg = body?['message'] as String? ??
          body?['error'] as String? ??
          'Generation failed (${response.statusCode})';
      return ApiResponse.failure(errorMsg, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.failure(ApiClient.friendlyError(e));
    }
  }
}
