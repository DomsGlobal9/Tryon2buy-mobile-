import '../../../core/network/api_response.dart';
import '../../shop/data/models/shop_item.dart';
import '../../shop/data/shop_repository.dart';
import 'models/dress_product_model.dart';

/// What shoppers browse: the demo collection, the same list the website
/// shows at `/shop/demo`.
///
/// The old `catalog-dresses` endpoint proxied a Django service that is not
/// deployed, so it always fell back to three mock dresses. Nothing on the
/// website uses it.
class CatalogRepository {
  final ShopRepository _shop;

  CatalogRepository({ShopRepository? shop}) : _shop = shop ?? ShopRepository();

  Future<ApiResponse<List<DressProductModel>>> fetchCatalogDresses({
    bool forceRefresh = false,
  }) async {
    final response = await _shop.fetchCollection(
      ShopRepository.demoVendorId,
      forceRefresh: forceRefresh,
    );
    final items = response.data;
    if (!response.success || items == null) {
      return ApiResponse.failure(
        response.error ?? 'Failed to load catalog',
        statusCode: response.statusCode,
      );
    }
    return ApiResponse.success(items.map(_toProduct).toList(growable: false));
  }

  static DressProductModel _toProduct(ShopItem item) => DressProductModel(
        id: item.id,
        name: item.title,
        category: item.category ?? 'Garment',
        // The collection carries no fabric; an empty subtitle is hidden.
        fabric: '',
        frontViewUrl: item.displayUrl,
        thumbnail: item.displayUrl,
        generationId: item.id,
      );
}
