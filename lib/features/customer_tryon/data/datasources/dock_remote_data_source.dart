import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:tryon2buy/core/constants/api_endpoints.dart';
import 'package:tryon2buy/core/errors/exceptions.dart';
import 'package:tryon2buy/core/network/api_client.dart';

/// Low-level HTTP data source for the dock backend routes.
///
/// Every method either returns parsed data or throws a typed [Exception].
/// The repository layer catches exceptions and maps them to [Failure] types.
///
/// All routes require a vendor JWT (`AuthRole.vendor`).
class DockRemoteDataSource {
  // ── List ────────────────────────────────────────────────────────────

  /// Everything the dock holds: photos with their nested try-on results.
  Future<Map<String, dynamic>> listPhotos() async {
    return _decodeMap(await _get(ApiEndpoints.dockList));
  }

  /// Garments customers have tried on, most recent first.
  Future<Map<String, dynamic>> listGarments() async {
    return _decodeMap(await _get(ApiEndpoints.dockGarments));
  }

  // ── Photos ──────────────────────────────────────────────────────────

  /// Adds a photo to the dock and returns its JSON.
  Future<Map<String, dynamic>> addPhoto(String imageUrl) async {
    return _decodeMap(
      await _post(ApiEndpoints.dockPhotos, {'imageUrl': imageUrl}),
    );
  }

  /// Makes one photo the active one.
  Future<Map<String, dynamic>> activatePhoto(String photoId) async {
    return _decodeMap(
      await _post(ApiEndpoints.dockPhotoActivate(photoId), {}),
    );
  }

  /// Clears the active selection.
  Future<Map<String, dynamic>> deactivateAll() async {
    return _decodeMap(
      await _post(ApiEndpoints.dockDeactivate, {}),
    );
  }

  /// Heartbeat — extends the 20-minute window and marks "in use".
  Future<Map<String, dynamic>> touchPhoto(String photoId) async {
    return _decodeMap(
      await _post(ApiEndpoints.dockPhotoTouch(photoId), {}),
    );
  }

  /// Removes a photo. Returns `{ "inUse": true }` on 409 (conflict).
  Future<Map<String, dynamic>> deletePhoto(
    String photoId, {
    bool force = false,
  }) async {
    final uri = Uri.parse(ApiEndpoints.dockPhotoDelete(photoId)).replace(
      queryParameters: force ? {'force': '1'} : null,
    );
    return _decodeMap(await _delete(uri));
  }

  // ── Garments ────────────────────────────────────────────────────────

  /// Heartbeat for a garment being viewed.
  Future<Map<String, dynamic>> touchGarment(String garmentId) async {
    return _decodeMap(
      await _post(ApiEndpoints.dockGarmentTouch(garmentId), {}),
    );
  }

  /// Removes a garment's try-on history. Returns `{ "inUse": true }` on 409.
  Future<Map<String, dynamic>> deleteGarment(
    String garmentId, {
    bool force = false,
  }) async {
    final uri = Uri.parse(ApiEndpoints.dockGarmentDelete(garmentId)).replace(
      queryParameters: force ? {'force': '1'} : null,
    );
    return _decodeMap(await _delete(uri));
  }

  // ── Results ─────────────────────────────────────────────────────────

  /// Removes a single try-on result.
  Future<Map<String, dynamic>> deleteResult(String resultId) async {
    return _decodeMap(
      await _delete(Uri.parse(ApiEndpoints.dockResultDelete(resultId))),
    );
  }

  // ── Clear ───────────────────────────────────────────────────────────

  /// Empties the entire dock.
  Future<Map<String, dynamic>> clearDock() async {
    return _decodeMap(
      await _delete(Uri.parse(ApiEndpoints.dockList)),
    );
  }

  // ─── Private Helpers ────────────────────────────────────────────────

  Future<http.Response> _get(String url) {
    return _guard(() async {
      final response = await ApiClient.client
          .get(Uri.parse(url), headers: await _headers())
          .timeout(ApiClient.timeoutDuration);
      await _guardStatus(response);
      return response;
    });
  }

  Future<http.Response> _post(String url, Map<String, dynamic> body) {
    return _guard(() async {
      final response = await ApiClient.client
          .post(Uri.parse(url), headers: await _headers(), body: jsonEncode(body))
          .timeout(ApiClient.timeoutDuration);
      await _guardStatus(response);
      return response;
    });
  }

  Future<http.Response> _delete(Uri uri) {
    return _guard(() async {
      final response = await ApiClient.client
          .delete(uri, headers: await _headers())
          .timeout(ApiClient.timeoutDuration);
      await _guardStatus(response);
      return response;
    });
  }

  Future<Map<String, String>> _headers() =>
      ApiClient.headers(role: AuthRole.vendor);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(statusCode: 0, message: e.toString());
    }
  }

  Future<void> _guardStatus(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    // 409 Conflict is not an error for dock operations — it means "in use".
    // Let the caller see it as data rather than an exception.
    if (response.statusCode == 409) return;

    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error']?.toString() ?? 'Server error ${response.statusCode}';
    } catch (_) {
      message = 'Server returned status ${response.statusCode}';
    }

    // Every dock route carries the vendor token, so a 401 here means that
    // token is dead. Drop it, exactly as the try-on data source does, or the
    // app goes on showing a signed-in merchant whose every request fails.
    // There is no guest quota on these routes, so no exception to make.
    if (response.statusCode == 401) {
      await ApiClient.onUnauthorized(AuthRole.vendor);
    }

    throw ServerException(statusCode: response.statusCode, message: message);
  }

  Map<String, dynamic> _decodeMap(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;
}
