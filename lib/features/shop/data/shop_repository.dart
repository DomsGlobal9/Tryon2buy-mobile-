import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'models/shop_item.dart';

/// A merchant's public collection, as the website's `/shop/:vendorId` page
/// reads it: `GET /api/tryon/vendor/:vendorId/gallery`. Public, no token.
///
/// `demo` is a special vendor id the backend maps to the master vendor's
/// catalog; it is what guests browse.
///
/// The home rail, the Discover tab and search all read the same list, so
/// one response is shared for a short while instead of three round trips
/// on every cold start. Pull-to-refresh bypasses it.
class ShopRepository {
  static const String demoVendorId = 'demo';

  static const Duration _cacheTtl = Duration(seconds: 90);
  static final Map<String, _CachedCollection> _cache = {};

  /// Drop everything cached, e.g. after a merchant saves a new drape.
  static void invalidateCache() => _cache.clear();

  Future<ApiResponse<List<ShopItem>>> fetchCollection(
    String vendorId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[vendorId];
    if (!forceRefresh && cached != null && !cached.isStale) {
      return ApiResponse.success(cached.items);
    }

    final response = await ApiClient.get<Map<String, dynamic>>(
      ApiEndpoints.vendorGallery(vendorId),
      role: AuthRole.none,
    );

    final generations = response.data?['generations'];
    if (!response.success || generations is! List) {
      // Offline with a warm cache: keep showing what we have.
      if (cached != null) return ApiResponse.success(cached.items);
      return ApiResponse.failure(
        response.error ?? 'Collection not found.',
        statusCode: response.statusCode,
      );
    }

    // Same rule as the website: only pieces with a finished AI result.
    final items = generations
        .whereType<Map<String, dynamic>>()
        .map(ShopItem.fromJson)
        .where((item) => item.resultImageUrl.isNotEmpty)
        .toList(growable: false);

    _cache[vendorId] = _CachedCollection(items, DateTime.now());
    return ApiResponse.success(items);
  }
}

class _CachedCollection {
  final List<ShopItem> items;
  final DateTime fetchedAt;

  const _CachedCollection(this.items, this.fetchedAt);

  bool get isStale =>
      DateTime.now().difference(fetchedAt) > ShopRepository._cacheTtl;
}
