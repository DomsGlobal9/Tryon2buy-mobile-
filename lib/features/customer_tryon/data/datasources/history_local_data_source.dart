import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/selfie_record.dart';

/// Local data source for managing the ephemeral selfie history dock.
///
/// Uses SharedPreferences as the backing store with JSON serialization.
/// Handles 20-minute TTL expiry and max 10 image cap.
class HistoryLocalDataSource {
  static const String _keyHistory = 'tryon_history_images';
  static const int _maxImages = 10;

  /// Returns all non-expired history records, cleaning up stale entries.
  Future<List<SelfieRecord>> getValidHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyHistory) ?? [];

    final List<SelfieRecord> valid = [];
    bool needsCleanup = false;

    for (final item in raw) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final record = _fromJson(decoded);
        if (!record.isExpired) {
          valid.add(record);
        } else {
          needsCleanup = true;
        }
      } catch (_) {
        needsCleanup = true;
      }
    }

    if (needsCleanup) {
      await _persist(prefs, valid);
    }

    return valid;
  }

  /// Save a new image URL to history. Sets it as active by default.
  Future<SelfieRecord> saveImage(String imageUrl, {bool setActive = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getValidHistory();

    final now = DateTime.now();
    final newRecord = SelfieRecord(
      id: now.millisecondsSinceEpoch.toString(),
      imageUrl: imageUrl,
      lastUsedAt: now,
      isActive: setActive,
    );

    final updated = [
      newRecord,
      ...history.map((r) => r.copyWith(isActive: setActive ? false : r.isActive)),
    ].take(_maxImages).toList();

    await _persist(prefs, updated);
    return newRecord;
  }

  /// Promote a specific record to active, deactivating all others.
  Future<void> promoteToActive(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getValidHistory();

    final updated = history.map((r) {
      return r.copyWith(isActive: r.id == id);
    }).toList();

    await _persist(prefs, updated);
  }

  /// Clear all history.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }

  // ─── Private ──────────────────────────────────────────────────────

  Future<void> _persist(SharedPreferences prefs, List<SelfieRecord> records) async {
    await prefs.setStringList(
      _keyHistory,
      records.map((r) => jsonEncode(_toJson(r))).toList(),
    );
  }

  SelfieRecord _fromJson(Map<String, dynamic> json) {
    return SelfieRecord(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      lastUsedAt: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _toJson(SelfieRecord record) {
    return {
      'id': record.id,
      'imageUrl': record.imageUrl,
      'timestamp': record.lastUsedAt.millisecondsSinceEpoch,
      'isActive': record.isActive,
    };
  }
}
