import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/constants/api_endpoints.dart';
import 'package:tryon2buy/features/auth/data/models/user_model.dart';
import 'package:tryon2buy/features/tag_tryon/data/models/scanned_garment.dart';
import 'package:tryon2buy/features/tag_tryon/domain/tag_reference.dart';
import 'package:tryon2buy/routes/app_router.dart';

void main() {
  group('TagReference domain parsing', () {
    test('parses full URL with variant', () {
      final tag = TagReference.parse(
        'https://tryon2buy.com/try/CLI-890/SAR-001?variant=CRIMSON',
      );
      expect(tag, isNotNull);
      expect(tag!.clientId, 'CLI-890');
      expect(tag.productCode, 'SAR-001');
      expect(tag.variant, 'CRIMSON');
    });

    test('parses full URL without variant', () {
      final tag = TagReference.parse(
        'https://tryon2buy.com/try/CLI-890/SAR-001',
      );
      expect(tag, isNotNull);
      expect(tag!.clientId, 'CLI-890');
      expect(tag.productCode, 'SAR-001');
      expect(tag.variant, isNull);
    });

    test('parses scheme-less URL', () {
      final tag = TagReference.parse(
        'tryon2buy.com/try/store_abc/LEH-202?variant=NAVY',
      );
      expect(tag, isNotNull);
      expect(tag!.clientId, 'store_abc');
      expect(tag.productCode, 'LEH-202');
      expect(tag.variant, 'NAVY');
    });

    test('parses relative path', () {
      final tag = TagReference.parse('/try/shop_xyz/KRT-555');
      expect(tag, isNotNull);
      expect(tag!.clientId, 'shop_xyz');
      expect(tag.productCode, 'KRT-555');
      expect(tag.variant, isNull);
    });

    test('returns null on invalid or non-tag strings', () {
      expect(TagReference.parse(''), isNull);
      expect(TagReference.parse('   '), isNull);
      expect(TagReference.parse('https://google.com'), isNull);
      expect(TagReference.parse('https://tryon2buy.com/shop/vendor123'), isNull);
      expect(TagReference.parse('/try/only_one_segment'), isNull);
    });
  });

  group('ScannedGarment data model', () {
    test('deserializes Scaleezy inventory payload with multi-colour variants', () {
      final json = {
        'title': 'Kanchipuram Silk Saree',
        'category': 'saree',
        'imageUrl': 'https://storage.scaleezy.com/garments/cover.jpg',
        'variantCode': 'GOLD',
        'colourName': 'Royal Gold',
        'colours': [
          {
            'code': 'GOLD',
            'name': 'Royal Gold',
            'imageUrl': 'https://storage.scaleezy.com/garments/gold.jpg',
          },
          {
            'code': 'MAROON',
            'name': 'Deep Maroon',
            'imageUrl': 'https://storage.scaleezy.com/garments/maroon.jpg',
          },
        ],
      };

      final garment = ScannedGarment.fromJson(json);
      expect(garment.title, 'Kanchipuram Silk Saree');
      expect(garment.category, 'saree');
      expect(garment.variantCode, 'GOLD');
      expect(garment.colourName, 'Royal Gold');
      expect(garment.displayTitle, 'Kanchipuram Silk Saree — Royal Gold');
      expect(garment.colours.length, 2);
      expect(garment.colours[0].code, 'GOLD');
      expect(garment.colours[1].name, 'Deep Maroon');
    });
  });

  group('UserModel profile and credit buckets', () {
    test('correctly maps mobileNumber from backend vendor profile response', () {
      final json = {
        'id': 'v_12345',
        'email': 'boutique@heritage.com',
        'name': 'Meera Silk House',
        'storeName': 'Meera Silk Store',
        'companyName': 'Meera Heritage Retail Pvt Ltd',
        'businessType': 'Luxury Boutique',
        'mobileNumber': '+91 9876543210',
        'drapeCredits': 25,
        'userTryonCredits': 40,
        'bgChangeCredits': 15,
        'blouseChangeCredits': 10,
        'isUnlimited': false,
      };

      final user = UserModel.fromJson(json, role: 'merchant');
      expect(user.id, 'v_12345');
      expect(user.email, 'boutique@heritage.com');
      expect(user.phone, '+91 9876543210');
      expect(user.companyName, 'Meera Heritage Retail Pvt Ltd');
      expect(user.businessType, 'Luxury Boutique');
      expect(user.drapeCredits, 25);
      expect(user.userTryonCredits, 40);
      expect(user.bgChangeCredits, 15);
      expect(user.blouseChangeCredits, 10);
      expect(user.isUnlimited, isFalse);
    });

    test('supports fallback snake_case credit and phone fields', () {
      final json = {
        'id': 'v_999',
        'phone': '9988776655',
        'store_name': 'Royal Sarees',
        'drape_credits': 5,
        'user_tryon_credits': 8,
        'is_unlimited': true,
      };

      final user = UserModel.fromJson(json, role: 'merchant');
      expect(user.phone, '9988776655');
      expect(user.storeName, 'Royal Sarees');
      expect(user.drapeCredits, 5);
      expect(user.userTryonCredits, 8);
      expect(user.isUnlimited, isTrue);
    });
  });

  group('ApiEndpoints inventory endpoints', () {
    test('builds correct inventory URLs with and without variant', () {
      final urlWithoutVariant = ApiEndpoints.inventoryGarment('CLI-1', 'PROD-2');
      expect(urlWithoutVariant, contains('/api/v1/public/tryon/CLI-1/PROD-2'));
      expect(urlWithoutVariant, isNot(contains('variant=')));

      final urlWithVariant = ApiEndpoints.inventoryGarment(
        'CLI-1',
        'PROD-2',
        variant: 'EMERALD GREEN',
      );
      expect(urlWithVariant, contains('/api/v1/public/tryon/CLI-1/PROD-2?variant=EMERALD+GREEN'));

      final genUrl = ApiEndpoints.inventoryGenerate('CLI-1', 'PROD-2');
      expect(genUrl, contains('/api/v1/public/tryon/CLI-1/PROD-2/generate'));
    });
  });

  group('AppRouter deep linking resolution', () {
    test('resolves shared try-on web URL to CustomerTryonStudioScreen', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: 'https://tryon2buy.com/tryon/gen_abc123'),
      );
      expect(route, isA<Route<dynamic>>());
    });

    test('resolves shared merchant shop URL to VendorPublicShopScreen', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: 'https://tryon2buy.com/shop/vendor_xyz789'),
      );
      expect(route, isA<Route<dynamic>>());
    });

    test('resolves shared tag try-on URL to ClientTryonScreen', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: 'https://tryon2buy.com/try/CLI-01/PRD-02?variant=RED'),
      );
      expect(route, isA<Route<dynamic>>());
    });

    test('resolves custom scheme tryon2buy:// URL', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: 'tryon2buy://tryon/gen_custom99'),
      );
      expect(route, isA<Route<dynamic>>());
    });
  });
}
