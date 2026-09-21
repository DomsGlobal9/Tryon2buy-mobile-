import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/core/utils/result.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/dock_facade.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/history_local_data_source.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/tryon_results_local_data_source.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/tryon_result.dart';
import 'package:tryon2buy/features/customer_tryon/domain/repositories/i_tryon_repository.dart';
import 'package:tryon2buy/features/customer_tryon/domain/usecases/change_background.dart';
import 'package:tryon2buy/features/customer_tryon/domain/usecases/generate_virtual_tryon.dart';
import 'package:tryon2buy/features/customer_tryon/domain/usecases/modify_outfit_style.dart';
import 'package:tryon2buy/features/customer_tryon/presentation/state/tryon_notifier.dart';
import 'package:tryon2buy/features/customer_tryon/presentation/state/tryon_state.dart';

TryonResult _drape(String id) => TryonResult(
      generationId: id,
      resultImageUrl: 'https://cdn/drape-$id.jpg',
      garmentImageUrl: 'https://cdn/garment.jpg',
      humanImageUrl: '',
      mode: 'with_garment',
      phase: 1,
      category: 'SAREE',
      status: 'COMPLETED',
    );

class _FakeRepo implements ITryonRepository {
  /// When set, `fetchGeneration` waits on it, so a test can act mid-load.
  Completer<Result<TryonResult>>? fetchGate;

  @override
  Future<Result<TryonResult>> fetchGeneration(String id) =>
      fetchGate?.future ?? Future.value(Success(_drape(id)));

  @override
  Future<Result<String>> uploadSelfie(File imageFile) async =>
      const Success('https://cdn/selfie.jpg');

  @override
  Future<Result<TryonResult>> executeTryon({
    required String garmentUrl,
    required String humanImageUrl,
    String mode = 'with_garment',
    String? parentGenerationId,
    String? category,
    String? targetFolder,
  }) async =>
      Success(TryonResult(
        generationId: 'gen-1',
        resultImageUrl: 'https://cdn/result.jpg',
        garmentImageUrl: garmentUrl,
        humanImageUrl: humanImageUrl,
        mode: mode,
        phase: 2,
        status: 'COMPLETED',
      ));

  @override
  Future<Result<String>> changeBackground({
    required String currentImageUrl,
    required String backgroundId,
    String? generationId,
  }) async =>
      const Success('https://cdn/bg.jpg');

  @override
  Future<Result<String>> modifyOutfitStyle({
    required String currentImageUrl,
    required String modificationType,
    String? generationId,
  }) async =>
      const Success('https://cdn/mod.jpg');
}

TryonNotifier _notifier(_FakeRepo repo) => TryonNotifier(
      repository: repo,
      generateTryon: GenerateVirtualTryonUseCase(repo),
      changeBackground: ChangeBackgroundUseCase(repo),
      modifyOutfit: ModifyOutfitStyleUseCase(repo),
      dock: DockFacade(
        remoteRepository: null,
        localHistory: HistoryLocalDataSource(),
        localResults: TryonResultsLocalDataSource(),
      ),
    );

/// Lets queued async work (the SharedPreferences mock) run.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a photo picked while the drape loads survives the load', () async {
    final repo = _FakeRepo()..fetchGate = Completer();
    final notifier = _notifier(repo);

    final opening = notifier.open(generationId: 'g1');
    await _settle();
    expect((notifier.state as TryonInitial).loadingSource, isTrue);

    notifier.selectFile(File('/tmp/selfie.jpg'));
    repo.fetchGate!.complete(Success(_drape('g1')));
    await opening;

    final state = notifier.state;
    expect(state, isA<TryonInitial>());
    expect((state as TryonInitial).loadingSource, isFalse);
    expect(state.session.selectedFile, isNotNull);
    expect(state.session.source?.generationId, 'g1');
    expect(state.session.hasSelfie, isTrue);
  });

  test('opening restores the active selfie and its results', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'tryon_history_images': [
        jsonEncode({
          'id': 's1',
          'imageUrl': 'https://cdn/selfie.jpg',
          'timestamp': now.millisecondsSinceEpoch,
          'isActive': true,
        }),
      ],
    });
    final repo = _FakeRepo();
    final notifier = _notifier(repo);

    await notifier.open(generationId: 'g1');
    expect(notifier.state, isA<TryonInitial>());
    expect(notifier.state.session.selectedUrl, 'https://cdn/selfie.jpg');

    await notifier.generate();
    final success = notifier.state;
    expect(success, isA<TryonSuccess>());
    expect((success as TryonSuccess).current.resultImageUrl, 'https://cdn/result.jpg');

    // A second open of the same drape lands on the carousel.
    final again = _notifier(repo);
    await again.open(generationId: 'g1');
    expect(again.state, isA<TryonSuccess>());
  });

  test('a retouch after the local cache expired keeps the carousel on screen', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'tryon_history_images': [
        jsonEncode({
          'id': 's1',
          'imageUrl': 'https://cdn/selfie.jpg',
          'timestamp': now.millisecondsSinceEpoch,
          'isActive': true,
        }),
      ],
    });
    final repo = _FakeRepo();
    final notifier = _notifier(repo);
    await notifier.open(generationId: 'g1');
    await notifier.generate();
    expect(notifier.state, isA<TryonSuccess>());

    // Age the stored result past the privacy window behind the notifier's back.
    final prefs = await SharedPreferences.getInstance();
    final old = now.subtract(const Duration(minutes: 25)).toIso8601String();
    final stored = jsonDecode(prefs.getString('tryon_results_by_selfie')!) as Map<String, dynamic>;
    for (final list in stored.values) {
      for (final entry in list as List) {
        (entry as Map<String, dynamic>)['lastUsedAt'] = old;
        entry['createdAt'] = old;
      }
    }
    await prefs.setString('tryon_results_by_selfie', jsonEncode(stored));

    notifier.selectBackground('bg1');
    await notifier.applyBackground();

    final state = notifier.state;
    expect(state, isA<TryonSuccess>());
    final success = state as TryonSuccess;
    expect(success.hasResults, isTrue);
    expect(success.isPostProcessing, isFalse);
    expect(success.current.resultImageUrl, 'https://cdn/bg.jpg');
    expect(success.pendingBackgroundId, isNull);
  });

  test('deleting the last result returns to the photo step', () async {
    final repo = _FakeRepo();
    final notifier = _notifier(repo);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    notifier.selectFile(File('/tmp/selfie.jpg'));
    await notifier.generate();
    final success = notifier.state as TryonSuccess;

    await notifier.deleteResult(success.current);

    expect(notifier.state, isA<TryonInitial>());
  });
}
