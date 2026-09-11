import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/tryon_result.dart';

/// The shopper's recent try-on results, grouped by the selfie they were
/// generated from — the mobile counterpart of the website's IndexedDB
/// `tryon_results` store that drives the result carousel.
///
/// Results follow the same 20-minute privacy window as the selfie history,
/// measured from their *last use* (generation, viewing, a retouch), so a look
/// the shopper keeps working on does not vanish under them. Anything older
/// is dropped on read.
class TryonResultsLocalDataSource {
  static const String _key = 'tryon_results_by_selfie';
  static const Duration expiry = Duration(minutes: 20);
  static const int _maxPerSelfie = 10;

  /// Bumped on every write that adds, edits or removes a result. Screens
  /// that hold a copy of the list — "My Looks" stays mounted in the shell's
  /// IndexedStack — listen to this and reload.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Results for one selfie, newest first. Reading them counts as use and
  /// extends their window, like the website's `pingSelfieActivity`.
  Future<List<TryonResult>> resultsFor(String selfieId) async {
    final all = await _readAll();
    final list = all[selfieId];
    if (list == null || list.isEmpty) return const <TryonResult>[];

    final now = DateTime.now();
    final touched = list.map((r) => r.copyWith(lastUsedAt: now)).toList();
    all[selfieId] = touched;
    await _writeAll(all, notify: false);
    return touched;
  }

  /// Every unexpired result across all selfies, newest first.
  Future<List<TryonResult>> allResults() async {
    final all = await _readAll();
    final flat = [for (final list in all.values) ...list];
    flat.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return flat;
  }

  /// Removes one result wherever it lives.
  Future<void> removeAnywhere(String generationId) async {
    final all = await _readAll();
    all.updateAll(
      (_, list) => list.where((r) => r.generationId != generationId).toList(),
    );
    await _writeAll(all);
  }

  /// Prepends [result] to the list for [selfieId] and returns the new list.
  Future<List<TryonResult>> add(String selfieId, TryonResult result) async {
    final all = await _readAll();
    final now = DateTime.now();
    final stamped = result.copyWith(
      createdAt: result.createdAt ?? now,
      lastUsedAt: now,
    );
    final updated = <TryonResult>[stamped, ...(all[selfieId] ?? const <TryonResult>[])]
        .take(_maxPerSelfie)
        .toList();
    all[selfieId] = updated;
    await _writeAll(all);
    return updated;
  }

  /// Replaces the result image of one entry (after a background swap or an
  /// outfit edit) and returns the new list. The list may come back without
  /// the entry if it expired between the read and the edit; callers keep
  /// their in-memory copy in that case.
  Future<List<TryonResult>> replaceImage(
    String selfieId,
    String generationId,
    String newImageUrl,
  ) async {
    final all = await _readAll();
    final now = DateTime.now();
    final updated = (all[selfieId] ?? const <TryonResult>[])
        .map((r) => r.generationId == generationId
            ? r.copyWith(resultImageUrl: newImageUrl, lastUsedAt: now)
            : r)
        .toList();
    all[selfieId] = updated;
    await _writeAll(all);
    return updated;
  }

  Future<List<TryonResult>> remove(String selfieId, String generationId) async {
    final all = await _readAll();
    final updated = (all[selfieId] ?? const <TryonResult>[])
        .where((r) => r.generationId != generationId)
        .toList();
    all[selfieId] = updated;
    await _writeAll(all);
    return updated;
  }

  // ── Storage ───────────────────────────────────────────────────────────

  static DateTime? _lastActivity(TryonResult r) => r.lastUsedAt ?? r.createdAt;

  Future<Map<String, List<TryonResult>>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};

    final cutoff = DateTime.now().subtract(expiry);
    final out = <String, List<TryonResult>>{};
    var pruned = false;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((selfieId, list) {
        if (list is! List) return;
        final all = list.whereType<Map<String, dynamic>>().map(_fromJson);
        final results = all.where((r) {
          final at = _lastActivity(r);
          return at == null || at.isAfter(cutoff);
        }).toList();
        if (results.length != all.length) pruned = true;
        if (results.isNotEmpty) out[selfieId] = results;
      });
    } catch (_) {
      // Corrupt cache is not worth surfacing; start clean.
      await prefs.remove(_key);
      return {};
    }
    // Expired entries are not just hidden: they are removed, so the file
    // stops growing and the images stop being referenced. Pruning is not a
    // change anyone needs to react to, so no revision bump.
    if (pruned) await _writeAll(out, notify: false);
    return out;
  }

  Future<void> _writeAll(
    Map<String, List<TryonResult>> all, {
    bool notify = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = all.map(
      (k, v) => MapEntry(k, v.map(_toJson).toList()),
    );
    await prefs.setString(_key, jsonEncode(encoded));
    if (notify) revision.value = revision.value + 1;
  }

  static Map<String, dynamic> _toJson(TryonResult r) => {
        'generationId': r.generationId,
        'resultImageUrl': r.resultImageUrl,
        'garmentImageUrl': r.garmentImageUrl,
        'humanImageUrl': r.humanImageUrl,
        'mode': r.mode,
        'phase': r.phase,
        'category': r.category,
        'vendorId': r.vendorId,
        'status': r.status,
        'createdAt': (r.createdAt ?? DateTime.now()).toIso8601String(),
        'lastUsedAt': r.lastUsedAt?.toIso8601String(),
      };

  static TryonResult _fromJson(Map<String, dynamic> j) => TryonResult(
        generationId: j['generationId'] as String? ?? '',
        resultImageUrl: j['resultImageUrl'] as String? ?? '',
        garmentImageUrl: j['garmentImageUrl'] as String? ?? '',
        humanImageUrl: j['humanImageUrl'] as String? ?? '',
        mode: j['mode'] as String? ?? 'with_garment',
        phase: j['phase'] as int? ?? 2,
        category: j['category'] as String?,
        vendorId: j['vendorId'] as String?,
        status: j['status'] as String? ?? 'COMPLETED',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
        lastUsedAt: DateTime.tryParse(j['lastUsedAt'] as String? ?? ''),
      );
}
