import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/tryon_results_local_data_source.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/tryon_result.dart';

Map<String, dynamic> _stored(
  String id, {
  required DateTime createdAt,
  DateTime? lastUsedAt,
}) =>
    {
      'generationId': id,
      'resultImageUrl': 'https://cdn/$id.jpg',
      'garmentImageUrl': 'https://cdn/garment.jpg',
      'humanImageUrl': 'https://cdn/selfie.jpg',
      'mode': 'with_garment',
      'phase': 2,
      'status': 'COMPLETED',
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };

TryonResult _result(String id) => TryonResult(
      generationId: id,
      resultImageUrl: 'https://cdn/$id.jpg',
      garmentImageUrl: 'https://cdn/garment.jpg',
      humanImageUrl: 'https://cdn/selfie.jpg',
      mode: 'with_garment',
      phase: 2,
      status: 'COMPLETED',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('results expire 20 minutes after last use, not after creation', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'tryon_results_by_selfie': jsonEncode({
        's1': [
          _stored('kept',
              createdAt: now.subtract(const Duration(minutes: 40)),
              lastUsedAt: now.subtract(const Duration(minutes: 5))),
          _stored('gone',
              createdAt: now.subtract(const Duration(minutes: 40)),
              lastUsedAt: now.subtract(const Duration(minutes: 25))),
          _stored('legacy', createdAt: now.subtract(const Duration(minutes: 3))),
        ],
      }),
    });

    final all = await TryonResultsLocalDataSource().allResults();

    expect(all.map((r) => r.generationId), containsAll(['kept', 'legacy']));
    expect(all.map((r) => r.generationId), isNot(contains('gone')));
  });

  test('add stamps lastUsedAt and bumps the revision', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TryonResultsLocalDataSource();
    final before = TryonResultsLocalDataSource.revision.value;

    final list = await store.add('s1', _result('g1'));

    expect(list.single.lastUsedAt, isNotNull);
    expect(list.single.createdAt, isNotNull);
    expect(TryonResultsLocalDataSource.revision.value, before + 1);
  });

  test('reading a selfie\'s results extends their window without notifying', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'tryon_results_by_selfie': jsonEncode({
        's1': [
          _stored('g1',
              createdAt: now.subtract(const Duration(minutes: 19)),
              lastUsedAt: now.subtract(const Duration(minutes: 19))),
        ],
      }),
    });
    final store = TryonResultsLocalDataSource();
    final before = TryonResultsLocalDataSource.revision.value;

    final list = await store.resultsFor('s1');

    expect(list.single.lastUsedAt!.isAfter(now.subtract(const Duration(minutes: 1))), isTrue);
    expect(TryonResultsLocalDataSource.revision.value, before);
  });

  test('replaceImage returns the list without an entry that expired meanwhile', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'tryon_results_by_selfie': jsonEncode({
        's1': [
          _stored('g1',
              createdAt: now.subtract(const Duration(minutes: 30)),
              lastUsedAt: now.subtract(const Duration(minutes: 30))),
        ],
      }),
    });

    final list = await TryonResultsLocalDataSource()
        .replaceImage('s1', 'g1', 'https://cdn/edited.jpg');

    expect(list, isEmpty);
  });
}
