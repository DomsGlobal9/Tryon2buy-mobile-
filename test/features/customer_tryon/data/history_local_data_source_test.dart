import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/history_local_data_source.dart';

/// A stored record, in the exact JSON shape the store persists.
String _record(String id, {required DateTime lastUsedAt, bool isActive = false}) =>
    jsonEncode({
      'id': id,
      'imageUrl': 'https://cdn/$id.jpg',
      'timestamp': lastUsedAt.millisecondsSinceEpoch,
      'isActive': isActive,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('promoting a photo restarts its 20-minute window; others keep theirs',
      () async {
    // The window is *sliding*: twenty minutes since the photo was last
    // used, not since it was uploaded. A shopper trying garments on for
    // nineteen minutes straight must not lose their photo at minute twenty.
    final now = DateTime.now();
    final fifteenAgo = now.subtract(const Duration(minutes: 15));
    final tenAgo = now.subtract(const Duration(minutes: 10));
    SharedPreferences.setMockInitialValues({
      'tryon_history_images': [
        _record('used', lastUsedAt: fifteenAgo, isActive: true),
        _record('other', lastUsedAt: tenAgo),
      ],
    });
    final store = HistoryLocalDataSource();

    await store.promoteToActive('used');

    final history = await store.getValidHistory();
    final used = history.singleWhere((r) => r.id == 'used');
    final other = history.singleWhere((r) => r.id == 'other');

    expect(used.isActive, isTrue);
    // Restarted: its clock now reads "just now", not fifteen minutes ago.
    expect(now.difference(used.lastUsedAt).inSeconds.abs(), lessThan(5));
    expect(used.remainingSeconds, greaterThan(19 * 60));

    expect(other.isActive, isFalse);
    // Untouched: promoting one photo must not extend the others.
    expect(other.lastUsedAt.millisecondsSinceEpoch, tenAgo.millisecondsSinceEpoch);
  });

  test('expired photos are purged on read, and the purge is persisted',
      () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'tryon_history_images': [
        _record('fresh', lastUsedAt: now.subtract(const Duration(minutes: 5))),
        _record('stale', lastUsedAt: now.subtract(const Duration(minutes: 21))),
      ],
    });
    final store = HistoryLocalDataSource();

    final history = await store.getValidHistory();

    expect(history.map((r) => r.id), ['fresh']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('tryon_history_images'), hasLength(1));
  });
}
