import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../constants/api_endpoints.dart';
import '../session/auth_session.dart';
import '../storage/local_storage_service.dart';
import '../utils/jwt_utils.dart';
import 'api_response.dart';
import 'auth_role.dart';

export 'auth_role.dart';

class ApiClient {
  /// Ordinary calls: lookups, uploads, saves.
  static const Duration timeoutDuration = Duration(seconds: 45);

  /// AI pipeline calls (`generate`, `catalog/generate`, `change-background`,
  /// `modify-outfit`). The server debits the credit *before* it runs the
  /// model, so a client that gives up early loses both the credit and the
  /// result. Multi-piece garments on a cold Render instance run well past
  /// the ordinary timeout.
  static const Duration generationTimeout = Duration(seconds: 120);

  /// One shared client, so connections are reused across calls and tests
  /// can swap in a `MockClient`.
  static http.Client client = http.Client();

  /// Request headers with the JWT for [role] attached, if one is stored.
  ///
  /// Public so the try-on data source, which drives its own `http` calls for
  /// finer error typing, uses the same token-selection rules instead of a
  /// second copy of them.
  static Future<Map<String, String>> headers({
    bool isMultipart = false,
    AuthRole role = AuthRole.any,
  }) async {
    final token = await tokenFor(role);
    return {
      'Accept': 'application/json',
      if (!isMultipart) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// The stored token a request with [role] would send, or null.
  ///
  /// A token past its `exp` is never sent: the `dev` backend's optional-auth
  /// routes would quietly treat the merchant as a guest, and the strict ones
  /// would 401. Dropping it here flips the app to signed-out at the same
  /// moment, so screens that listen to [AuthSession] react at once.
  static Future<String?> tokenFor(AuthRole role) async {
    if (role == AuthRole.none) return null;
    final storage = await LocalStorageService.getInstance();
    final token = storage.getVendorToken();
    if (token == null || token.isEmpty) return null;
    if (JwtUtils.isExpired(token)) {
      await AuthSession.instance.invalidate(AuthRole.vendor);
      return null;
    }
    return token;
  }

  /// Wraps [file] as a multipart part with its sniffed MIME type.
  static Future<http.MultipartFile> multipartFile(
    File file, {
    String field = 'image',
  }) {
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');
    final mediaType = MediaType(
      mimeParts[0],
      mimeParts.length > 1 ? mimeParts[1] : 'jpeg',
    );
    return http.MultipartFile.fromPath(field, file.path, contentType: mediaType);
  }

  /// Called for every 401. If the request actually carried a token, that
  /// token is dead (expired or revoked), so drop it and let account-aware
  /// screens fall back to their signed-out state instead of showing a
  /// signed-in profile that every request rejects.
  static Future<void> onUnauthorized(AuthRole role) async {
    if (role == AuthRole.none) return;
    final storage = await LocalStorageService.getInstance();
    final token = storage.getVendorToken();
    if (token == null || token.isEmpty) return;
    await AuthSession.instance.invalidate(AuthRole.vendor);
  }

  /// A key for one generation attempt, sent as `client_request_id`.
  ///
  /// Opaque to the server, which only needs it to be unique and unguessable;
  /// it is the handle used to recover a result whose response was lost.
  static String newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}-$hex';
  }

  /// Asks the server what became of the generation sent under [clientRequestId].
  ///
  /// Returns the completed payload, or null when the work failed, was never
  /// started, or is still running after the window below. The credit is
  /// already spent by the time a response goes missing, so it is worth
  /// waiting a while rather than making the user pay twice.
  static Future<Map<String, dynamic>?> recoverGeneration(
    String clientRequestId, {
    int attempts = 6,
  }) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      await Future<void>.delayed(
        Duration(seconds: attempt == 0 ? 2 : 10),
      );

      final res = await get<Map<String, dynamic>>(
        ApiEndpoints.generationStatus(clientRequestId),
        role: AuthRole.none,
      );

      // A 404 means the request never reached the server, so there is
      // nothing to wait for and nothing was charged.
      if (res.statusCode == 404) return null;

      final data = res.data;
      if (!res.success || data == null) continue;

      switch (data['status']) {
        case 'COMPLETED':
          return data;
        case 'FAILED':
          return null;
        default:
          continue; // still running
      }
    }
    return null;
  }

  /// Turns transport and parsing exceptions into something a user can read.
  static String friendlyError(Object error) {
    if (error is SocketException || error is http.ClientException) {
      return 'No internet connection. Please check your network.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is FormatException) {
      return 'The server sent an unexpected response.';
    }
    return 'Something went wrong. Please try again.';
  }

  static Future<ApiResponse<T>> get<T>(
    String url, {
    T Function(dynamic data)? fromJson,
    AuthRole role = AuthRole.any,
    Duration timeout = timeoutDuration,
  }) {
    return _send(role, fromJson, () async {
      return client
          .get(Uri.parse(url), headers: await headers(role: role))
          .timeout(timeout);
    });
  }

  static Future<ApiResponse<T>> post<T>(
    String url, {
    Map<String, dynamic>? body,
    T Function(dynamic data)? fromJson,
    AuthRole role = AuthRole.any,
    Duration timeout = timeoutDuration,
  }) {
    return _send(role, fromJson, () async {
      return client
          .post(
            Uri.parse(url),
            headers: await headers(role: role),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
    });
  }

  static Future<ApiResponse<T>> put<T>(
    String url, {
    Map<String, dynamic>? body,
    T Function(dynamic data)? fromJson,
    AuthRole role = AuthRole.any,
    Duration timeout = timeoutDuration,
  }) {
    return _send(role, fromJson, () async {
      return client
          .put(
            Uri.parse(url),
            headers: await headers(role: role),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
    });
  }

  static Future<ApiResponse<T>> delete<T>(
    String url, {
    T Function(dynamic data)? fromJson,
    AuthRole role = AuthRole.any,
    Duration timeout = timeoutDuration,
  }) {
    return _send(role, fromJson, () async {
      return client
          .delete(Uri.parse(url), headers: await headers(role: role))
          .timeout(timeout);
    });
  }

  static Future<ApiResponse<T>> postMultipart<T>(
    String url, {
    required File file,
    String fileFieldName = 'image',
    Map<String, String>? queryParams,
    T Function(dynamic data)? fromJson,
    AuthRole role = AuthRole.any,
    Duration timeout = timeoutDuration,
  }) {
    return _send(role, fromJson, () async {
      var uri = Uri.parse(url);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(await headers(isMultipart: true, role: role))
        ..files.add(await multipartFile(file, field: fileFieldName));

      final streamed = await client.send(request).timeout(timeout);
      return http.Response.fromStream(streamed);
    });
  }

  // ── Internals ──────────────────────────────────────────────────────────

  /// One place for the try/catch, the 401 hook and the status mapping, so the
  /// four verbs cannot drift apart.
  static Future<ApiResponse<T>> _send<T>(
    AuthRole role,
    T Function(dynamic data)? fromJson,
    Future<http.Response> Function() perform,
  ) async {
    try {
      final response = await perform();
      final parsed = _handleResponse(response, fromJson);
      // A guest-limit 401 is a quota, not a dead token; leave the session be.
      if (response.statusCode == 401 && !parsed.isGuestLimitReached) {
        await onUnauthorized(role);
      }
      return parsed;
    } catch (e) {
      return ApiResponse.failure(friendlyError(e));
    }
  }

  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic data)? fromJson,
  ) {
    final statusCode = response.statusCode;
    dynamic body;

    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final parsedData = fromJson != null ? fromJson(body) : body as T;
        return ApiResponse.success(parsedData, statusCode: statusCode);
      } catch (_) {
        // A 200 whose body is not the shape we expected (HTML from a proxy,
        // a list where a map was promised). Surface it as a failure rather
        // than letting a cast error escape to the UI.
        return ApiResponse.failure(
          'The server sent an unexpected response.',
          statusCode: statusCode,
        );
      }
    }

    // Business failures arrive as `{ error: 'SOME_CODE', message: '…' }`;
    // ordinary ones as `{ error: 'Readable text' }`.
    final rawError = body is Map ? body['error']?.toString() : null;
    final rawMessage = body is Map ? body['message']?.toString() : null;
    final isCode = rawError != null && _errorCodePattern.hasMatch(rawError);
    final code = isCode ? rawError : null;
    final serverMessage = isCode ? (rawMessage ?? rawError) : (rawError ?? rawMessage);

    final message = switch (statusCode) {
      401 => serverMessage ?? 'Please sign in to continue.',
      403 => serverMessage ?? 'You do not have permission to do that.',
      404 => serverMessage ?? 'That item could not be found.',
      >= 500 => serverMessage ?? 'The server had a problem. Please try again shortly.',
      _ => serverMessage ?? 'Request failed (status $statusCode).',
    };

    return ApiResponse.failure(message, statusCode: statusCode, errorCode: code);
  }

  static final _errorCodePattern = RegExp(r'^[A-Z][A-Z0-9_]{3,}$');
}
