import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tryon2buy/core/constants/api_endpoints.dart';
import 'package:tryon2buy/core/errors/exceptions.dart';
import 'package:tryon2buy/core/network/api_client.dart';
import '../models/tryon_generation_dto.dart';

/// Low-level HTTP data source for the try-on backend.
///
/// Every method either returns parsed data or throws a typed [Exception].
/// The repository layer catches exceptions and maps them to [Failure] types.
///
/// Token selection, the shared client, timeouts and multipart encoding are
/// borrowed from [ApiClient] so the two HTTP paths cannot drift apart; only
/// the error typing differs.
class TryonRemoteDataSource {
  /// Uploads a selfie [File] and returns the hosted URL.
  /// Throws [ServerException], [NetworkException], or [RequestTimeoutException].
  Future<String> uploadSelfie(File file) async {
    return _guard(() async {
      // The server only accepts a fixed set of folders; shopper photos go to
      // `user-uploads`, as on the website. (`human-images` was rejected.)
      final uri = Uri.parse(ApiEndpoints.uploadImage).replace(
        queryParameters: {'folder': ApiEndpoints.folderUserUploads},
      );

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(await ApiClient.headers(isMultipart: true))
        ..files.add(await ApiClient.multipartFile(file));

      final streamed =
          await ApiClient.client.send(request).timeout(ApiClient.timeoutDuration);
      final response = await http.Response.fromStream(streamed);
      await _guardStatus(response, AuthRole.any);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final url = body['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ImageException('Server returned no image URL.');
      }
      return url;
    });
  }

  /// Calls the AI try-on pipeline. Returns the parsed DTO.
  Future<TryonGenerationDto> generateTryon({
    required String garmentUrl,
    required String humanImageUrl,
    String mode = 'with_garment',
    String? parentGenerationId,
    String? category,
    String? garmentId,
    String? catalogProductId,
    String? frontViewUrl,
    String? targetFolder,
  }) async {
    // The server records this against the row before it calls the model, so
    // a result whose response is lost can still be claimed afterwards.
    final clientRequestId = ApiClient.newRequestId();

    final body = <String, dynamic>{
      'mode': mode,
      'garment_image_url': garmentUrl,
      'human_image_url': humanImageUrl,
      'client_request_id': clientRequestId,
      if (category != null) 'category': category,
      if (parentGenerationId != null) 'parent_generation_id': parentGenerationId,
      if (targetFolder != null) 'target_folder': targetFolder,
      // Links the row back to its source so the vendor gallery and catalog
      // can join on it. All three are optional on the server.
      if (garmentId != null) 'garment_id': garmentId,
      if (catalogProductId != null) 'catalog_product_id': catalogProductId,
      if (frontViewUrl != null) 'front_view_url': frontViewUrl,
    };

    try {
      final response = await _post(
        ApiEndpoints.generateTryon,
        body,
        timeout: ApiClient.generationTimeout,
      );
      return TryonGenerationDto.fromJson(_decodeMap(response));
    } on RequestTimeoutException {
      return await _recoverOrRethrow(clientRequestId, const RequestTimeoutException());
    } on NetworkException {
      return await _recoverOrRethrow(clientRequestId, const NetworkException());
    }
  }

  /// Last chance to claim a generation whose response never arrived.
  ///
  /// The credit was spent the moment the server started work, so a dropped
  /// connection would otherwise cost the shopper a try-on and leave the
  /// finished image unreachable. If nothing can be claimed, the original
  /// transport failure is what the user should see.
  Future<TryonGenerationDto> _recoverOrRethrow(
    String clientRequestId,
    Exception original,
  ) async {
    final recovered = await ApiClient.recoverGeneration(clientRequestId);
    if (recovered != null) return TryonGenerationDto.fromJson(recovered);
    throw original;
  }

  /// Swap background. Returns the new result image URL.
  Future<String> changeBackground({
    required String imageUrl,
    required String backgroundId,
    String? generationId,
  }) async {
    final response = await _post(
      ApiEndpoints.changeBackground,
      {
        'imageUrl': imageUrl,
        'backgroundId': backgroundId,
        if (generationId != null) 'generationId': generationId,
      },
      // Whichever token exists; a guest sends none and the server applies
      // its free-tier limit, as on the website.
      role: AuthRole.any,
      timeout: ApiClient.generationTimeout,
    );
    return _requireUrl(_decodeMap(response)['url'],
        'Background swap returned no URL.');
  }

  /// Modify outfit. Returns the new result image URL.
  Future<String> modifyOutfit({
    required String imageUrl,
    required String modificationType,
    String? generationId,
  }) async {
    final response = await _post(
      ApiEndpoints.modifyOutfit,
      {
        'imageUrl': imageUrl,
        'modificationType': modificationType,
        if (generationId != null) 'generationId': generationId,
      },
      // Whichever token exists; a guest sends none and the server applies
      // its free-tier limit, as on the website.
      role: AuthRole.any,
      timeout: ApiClient.generationTimeout,
    );
    // modify-outfit returns `resultImageUrl`; only change-background
    // returns `url`.
    return _requireUrl(_decodeMap(response)['resultImageUrl'],
        'Outfit modification returned no URL.');
  }

  /// Fetch a single generation by ID.
  Future<TryonGenerationDto> fetchGeneration(String id) async {
    final response = await _get(ApiEndpoints.singleGeneration(id));
    return TryonGenerationDto.fromJson(_decodeMap(response));
  }

  // ─── Private Helpers ─────────────────────────────────────────────

  Future<http.Response> _post(
    String url,
    Map<String, dynamic> body, {
    AuthRole role = AuthRole.any,
    Duration timeout = ApiClient.timeoutDuration,
  }) {
    return _guard(() async {
      final response = await ApiClient.client
          .post(
            Uri.parse(url),
            headers: await ApiClient.headers(role: role),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      await _guardStatus(response, role);
      return response;
    });
  }

  Future<http.Response> _get(
    String url, {
    AuthRole role = AuthRole.any,
    Duration timeout = ApiClient.timeoutDuration,
  }) {
    return _guard(() async {
      final response = await ApiClient.client
          .get(Uri.parse(url), headers: await ApiClient.headers(role: role))
          .timeout(timeout);
      await _guardStatus(response, role);
      return response;
    });
  }

  /// Translates transport errors into the typed exceptions the repository
  /// expects, and lets already-typed ones through untouched.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      // The http package reports connection resets and DNS failures this
      // way rather than as a SocketException.
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on ServerException {
      rethrow;
    } on ImageException {
      rethrow;
    } catch (e) {
      throw ServerException(statusCode: 0, message: e.toString());
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;

  String _requireUrl(Object? value, String errorMessage) {
    final url = value as String?;
    if (url == null || url.isEmpty) throw ImageException(errorMessage);
    return url;
  }

  /// Throws [ServerException] for non-2xx responses. A 401 that is not the
  /// guest quota also drops the rejected token so the rest of the app stops
  /// treating it as signed in.
  Future<void> _guardStatus(http.Response response, AuthRole role) async {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message;
    String? code;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      code = body['error']?.toString();
      message = body['message']?.toString() ??
          code ??
          'Server error ${response.statusCode}';
    } catch (_) {
      message = 'Server returned status ${response.statusCode}';
    }

    if (response.statusCode == 401 && code != 'GUEST_LIMIT_REACHED') {
      await ApiClient.onUnauthorized(role);
    }

    throw ServerException(
      statusCode: response.statusCode,
      message: message,
      rawBody: response.body,
    );
  }
}
