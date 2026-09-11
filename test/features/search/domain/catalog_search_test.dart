import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/features/catalog/data/models/dress_product_model.dart';
import 'package:tryon2buy/features/search/domain/catalog_search.dart';

DressProductModel _product(String id, String name, String category, String fabric) =>
    DressProductModel(
      id: id,
      name: name,
      category: category,
      fabric: fabric,
      frontViewUrl: 'https://example.com/$id.jpg',
      thumbnail: 'https://example.com/$id-thumb.jpg',
    );

void main() {
  final products = [
    _product('1', 'Banarasi Silk Saree', 'SAREE', 'Silk'),
    _product('2', 'Cotton Kurti', 'KURTI', 'Cotton'),
    _product('3', 'Bridal Lehenga', 'lehenga', 'Velvet'),
    _product('4', 'Printed Saree', 'Saree', 'Georgette'),
  ];

  group('CatalogSearch.filter', () {
    test('returns everything with no query and the ALL category', () {
      expect(CatalogSearch.filter(products), hasLength(4));
    });

    test('matches every word of the query across name, fabric and category', () {
      final hits = CatalogSearch.filter(products, query: 'silk saree');
      expect(hits.map((p) => p.id), ['1']);
    });

    test('is case-insensitive and tolerant of extra whitespace', () {
      final hits = CatalogSearch.filter(products, query: '  COTTON   ');
      expect(hits.map((p) => p.id), ['2']);
    });

    test('filters by category regardless of the category casing in data', () {
      final hits = CatalogSearch.filter(products, category: 'saree');
      expect(hits.map((p) => p.id), ['1', '4']);
    });

    test('combines query and category', () {
      final hits =
          CatalogSearch.filter(products, query: 'printed', category: 'SAREE');
      expect(hits.map((p) => p.id), ['4']);
    });

    test('returns nothing for a word no product contains', () {
      expect(CatalogSearch.filter(products, query: 'sherwani'), isEmpty);
    });
  });

  group('CatalogSearch.categoriesOf', () {
    test('starts with ALL, de-duplicates by case and sorts', () {
      expect(
        CatalogSearch.categoriesOf(products),
        ['ALL', 'KURTI', 'LEHENGA', 'SAREE'],
      );
    });

    test('includes the extra category even when no product has it', () {
      expect(
        CatalogSearch.categoriesOf(products, extra: 'blouse'),
        contains('BLOUSE'),
      );
    });
  });

  test('label title-cases keys and names the ALL key', () {
    expect(CatalogSearch.label('SAREE'), 'Saree');
    expect(CatalogSearch.label(CatalogSearch.all), 'All');
  });
}
