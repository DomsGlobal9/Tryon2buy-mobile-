import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/session/auth_session.dart';
import 'package:tryon2buy/core/storage/local_storage_service.dart';
import 'package:tryon2buy/core/utils/result.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/dock_facade.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/history_local_data_source.dart';
import 'package:tryon2buy/features/customer_tryon/data/datasources/tryon_results_local_data_source.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/dock_garment.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/dock_photo.dart';
import 'package:tryon2buy/features/customer_tryon/domain/entities/tryon_result.dart';
import 'package:tryon2buy/features/customer_tryon/domain/repositories/i_dock_repository.dart';
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

/// The order in which the fakes were hit. The dock fix is about *sequence*
/// (a merchant's photo must be docked before the pipeline runs, and only
/// once), so tests assert on this rather than on call counts alone.
final _log = <String>[];

class _FakeRepo implements ITryonRepository {
  /// When set, `fetchGeneration` waits on it, so a test can act mid-load.
  Completer<Result<TryonResult>>? fetchGate;

  /// What the last `executeTryon` was asked to send, so a test can check the
  /// dock link travelled with the request.
  String? lastDockPhotoId;
  String? lastHumanImageUrl;
  int uploadCalls = 0;

  @override
  Future<Result<TryonResult>> fetchGeneration(String id) =>
      fetchGate?.future ?? Future.value(Success(_drape(id)));

  @override
  Future<Result<String>> uploadSelfie(File imageFile) async {
    uploadCalls++;
    _log.add('upload');
    return const Success('https://cdn/selfie.jpg');
  }

  @override
  Future<Result<TryonResult>> executeTryon({
    required String garmentUrl,
    required String humanImageUrl,
    String mode = 'with_garment',
    String? parentGenerationId,
    String? category,
    String? targetFolder,
    String? dupattaStyleUrl,
    String? dockPhotoId,
  }) async {
    lastDockPhotoId = dockPhotoId;
    lastHumanImageUrl = humanImageUrl;
    _log.add('execute');
    return Success(TryonResult(
        generationId: 'gen-1',
        resultImageUrl: 'https://cdn/result.jpg',
        garmentImageUrl: garmentUrl,
        humanImageUrl: humanImageUrl,
        mode: mode,
        phase: 2,
        status: 'COMPLETED',
      ));
  }

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

/// The server-side dock, as the notifier sees it when a merchant is signed
/// in. Photos it hands out carry ids the real server would recognise, which
/// is what the guard in `generate()` checks against.
class _FakeDock implements IDockRepository {
  List<DockPhoto> photos;
  List<DockGarment> garments;
  int addPhotoCalls = 0;
  final activated = <String>[];
  final touchedGarments = <String>[];
  final touchedPhotos = <String>[];

  /// When set, an un-forced delete fails with it (a 409 "in use").
  Failure? deleteGarmentFailure;
  final deleteGarmentCalls = <({String id, bool force})>[];

  Failure? deletePhotoFailure;
  final deletePhotoCalls = <({String id, bool force})>[];
  final deletedResults = <String>[];

  _FakeDock({this.photos = const [], this.garments = const []});

  @override
  Future<Result<List<DockPhoto>>> listPhotos() async => Success(photos);

  @override
  Future<Result<DockPhoto>> addPhoto(String imageUrl) async {
    addPhotoCalls++;
    _log.add('addPhoto');
    final photo = DockPhoto(id: 'dock-photo-$addPhotoCalls', imageUrl: imageUrl);
    photos = [...photos, photo];
    return Success(photo);
  }

  @override
  Future<Result<DockPhoto>> activatePhoto(String photoId) async {
    activated.add(photoId);
    _log.add('activate');
    final photo = photos.firstWhere(
      (p) => p.id == photoId,
      orElse: () => DockPhoto(id: photoId, imageUrl: ''),
    );
    return Success(photo.copyWith(isActive: true));
  }

  @override
  Future<Result<void>> deactivateAll() async => const Success<void>(null);

  @override
  Future<Result<void>> touchPhoto(String photoId) async {
    touchedPhotos.add(photoId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {bool force = false}) async {
    deletePhotoCalls.add((id: photoId, force: force));
    final refusal = deletePhotoFailure;
    if (refusal != null && !force) return Fail(refusal);
    photos = photos.where((p) => p.id != photoId).toList();
    return const Success<void>(null);
  }

  @override
  Future<Result<List<DockGarment>>> listGarments() async => Success(garments);

  @override
  Future<Result<void>> touchGarment(String garmentId) async {
    touchedGarments.add(garmentId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteGarment(String garmentId, {bool force = false}) async {
    deleteGarmentCalls.add((id: garmentId, force: force));
    final refusal = deleteGarmentFailure;
    if (refusal != null && !force) return Fail(refusal);
    garments = garments.where((g) => g.id != garmentId).toList();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteResult(String resultId) async {
    deletedResults.add(resultId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> clearDock() async => const Success<void>(null);
}

/// The heartbeat is off by default so no test leaves a periodic timer running;
/// the one test that exercises it passes a tiny interval of its own.
TryonNotifier _notifier(
  _FakeRepo repo, {
  IDockRepository? dock,
  Duration? heartbeat,
}) =>
    TryonNotifier(
      repository: repo,
      generateTryon: GenerateVirtualTryonUseCase(repo),
      changeBackground: ChangeBackgroundUseCase(repo),
      modifyOutfit: ModifyOutfitStyleUseCase(repo),
      heartbeat: heartbeat,
      dock: DockFacade(
        remoteRepository: dock,
        localHistory: HistoryLocalDataSource(),
        localResults: TryonResultsLocalDataSource(),
      ),
    );

/// Signs a merchant in the way the app decides it: a stored token that is
/// not past its `exp`. An opaque token has no `exp`, so it never expires.
Future<void> _signInVendor({Map<String, Object> extra = const {}}) async {
  LocalStorageService.resetForTests();
  AuthSession.instance.resetForTests();
  SharedPreferences.setMockInitialValues({'vendor_token': 'vend-token', ...extra});
  await AuthSession.instance.refresh();
}

/// Lets queued async work (the SharedPreferences mock) run.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _log.clear();
    // Both singletons cache a storage handle; without dropping it a merchant
    // signed in by one test would still look signed in to the next.
    LocalStorageService.resetForTests();
    AuthSession.instance.resetForTests();
    SharedPreferences.setMockInitialValues({});
  });

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

  // ── dock_photo_id ───────────────────────────────────────────────────
  //
  // The server groups a try-on under a dock photograph only by the
  // `dock_photo_id` stamped at generation time, so for a merchant the id has
  // to exist *before* the pipeline runs and must travel with the request.

  test('a merchant\'s fresh photo is docked before generating, once, and its id is sent',
      () async {
    await _signInVendor();
    final repo = _FakeRepo();
    final dock = _FakeDock();
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    notifier.selectFile(File('/tmp/selfie.jpg'));

    await notifier.generate();

    expect(notifier.state, isA<TryonSuccess>());
    // Upload first (so there is a URL to dock), dock, then generate with the
    // id; the success path activates it rather than adding it a second time.
    expect(_log, ['upload', 'addPhoto', 'execute', 'activate']);
    expect(repo.uploadCalls, 1);
    expect(repo.lastHumanImageUrl, 'https://cdn/selfie.jpg');
    expect(repo.lastDockPhotoId, 'dock-photo-1');
    expect(dock.addPhotoCalls, 1);
    expect(dock.activated, ['dock-photo-1']);
    expect(notifier.state.session.activeHistoryId, 'dock-photo-1');
  });

  test('a photo already in the merchant dock is sent by its server id, with no re-upload',
      () async {
    await _signInVendor();
    final docked = DockPhoto(id: 'dp-9', imageUrl: 'https://cdn/dp9.jpg');
    final repo = _FakeRepo();
    final dock = _FakeDock(photos: [docked]);
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    await notifier.switchDockPhoto(docked);
    _log.clear();

    await notifier.generate();

    expect(notifier.state, isA<TryonSuccess>());
    expect(repo.uploadCalls, 0);
    expect(dock.addPhotoCalls, 0);
    expect(repo.lastDockPhotoId, 'dp-9');
    expect(repo.lastHumanImageUrl, 'https://cdn/dp9.jpg');
  });

  test('a selfie id restored from the local store is not sent as a dock photo id',
      () async {
    // open() restores the active selfie from the on-device store even for a
    // merchant, so activeHistoryId can be a *local* id. The server would not
    // know it; sending it would stamp a meaningless link on the result.
    await _signInVendor(extra: {
      'tryon_history_images': [
        jsonEncode({
          'id': 's1',
          'imageUrl': 'https://cdn/selfie.jpg',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isActive': true,
        }),
      ],
    });
    final repo = _FakeRepo();
    final dock = _FakeDock(); // the server dock has never heard of 's1'
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    expect(notifier.state.session.activeHistoryId, 's1');

    await notifier.generate();

    expect(notifier.state, isA<TryonSuccess>());
    expect(repo.lastDockPhotoId, isNull);
    expect(dock.addPhotoCalls, 0);
  });

  // ── Tried outfits ───────────────────────────────────────────────────

  test('"Try This" swaps the garment on the canvas and keeps the photo',
      () async {
    await _signInVendor();
    final docked = DockPhoto(id: 'dp-9', imageUrl: 'https://cdn/dp9.jpg');
    const outfit = DockGarment(
      id: 'prod-1',
      primaryAssetId: 'asset-7',
      title: 'Banarasi Saree',
      category: 'SAREE',
    );
    final repo = _FakeRepo();
    final dock = _FakeDock(photos: [docked], garments: const [outfit]);
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    expect(notifier.state.session.dockGarments, [outfit]);
    await notifier.switchDockPhoto(docked);

    await notifier.switchGarment(outfit);

    final state = notifier.state;
    expect(state, isA<TryonInitial>());
    expect((state as TryonInitial).loadingSource, isFalse);
    // The garment changed …
    expect(state.session.source?.generationId, 'asset-7');
    expect(state.session.garmentUrl, 'https://cdn/drape-asset-7.jpg');
    // … the photo did not.
    expect(state.session.selectedUrl, 'https://cdn/dp9.jpg');
    expect(state.session.activeHistoryId, 'dp-9');
    // And the shop was told this outfit is open.
    expect(dock.touchedGarments, ['prod-1']);
  });

  test('an open room keeps telling the server it is in use', () async {
    // Two jobs, and nothing else does either: the beat keeps the photo's
    // 20-minute window sliding while the merchant retouches rather than
    // generates, and it is the only thing that makes a colleague deleting
    // the photo or the outfit elsewhere get asked before taking it away.
    await _signInVendor();
    final docked = DockPhoto(id: 'dp-9', imageUrl: 'https://cdn/dp9.jpg');
    final repo = _FakeRepo();
    final dock = _FakeDock(photos: [docked]);
    final notifier = _notifier(repo,
        dock: dock, heartbeat: const Duration(milliseconds: 20));
    addTearDown(notifier.dispose);

    await notifier.open(generationId: 'g1');
    // The garment is claimed by the asset id the room is addressed by, from
    // the moment it opens — a colleague can already see it in their dock.
    expect(dock.touchedGarments, contains('g1'));

    await notifier.switchDockPhoto(docked);
    expect(dock.touchedPhotos, contains('dp-9'),
        reason: 'a photo is claimed the moment it is picked, not 30s later');

    final beatsSoFar = dock.touchedPhotos.length;
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(dock.touchedPhotos.length, greaterThan(beatsSoFar),
        reason: 'the beat goes on while the room stays open');
    expect(dock.touchedPhotos.toSet(), {'dp-9'});
  });

  test('a guest room beats nothing — there is no server dock to tell',
      () async {
    final repo = _FakeRepo();
    final dock = _FakeDock();
    // Not signed in, so the facade is in local mode.
    final notifier = _notifier(repo,
        dock: dock, heartbeat: const Duration(milliseconds: 20));
    addTearDown(notifier.dispose);

    await notifier.open(generationId: 'g1');
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(dock.touchedPhotos, isEmpty);
    expect(dock.touchedGarments, isEmpty);
  });

  test('a retouch in flight refuses a garment swap', () async {
    // Browsing the dock stays allowed while something is generating — that is
    // exactly when a shopper looks for what to try next. Applying does not:
    // the retouch would come back belonging to a garment nobody chose it with.
    await _signInVendor();
    const outfit = DockGarment(id: 'prod-1', primaryAssetId: 'asset-7');
    final repo = _FakeRepo();
    final dock = _FakeDock(garments: const [outfit]);
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    notifier.selectFile(File('/tmp/selfie.jpg'));
    await notifier.generate();

    // A background change is running.
    notifier.selectBackground('bg1');
    final applying = notifier.applyBackground();
    expect((notifier.state as TryonSuccess).isPostProcessing, isTrue);

    await notifier.switchGarment(outfit);

    expect(notifier.state, isA<TryonSuccess>(),
        reason: 'the retouch was not thrown off its own screen');
    expect(dock.touchedGarments, isEmpty);
    await applying;
    expect(notifier.state.session.source, isNull,
        reason: 'no garment was swapped in');
  });

  test('removing an outfit a colleague is fitting reports the conflict, then forces',
      () async {
    await _signInVendor();
    const outfit = DockGarment(id: 'prod-1', primaryAssetId: 'asset-7');
    final repo = _FakeRepo();
    final dock = _FakeDock(garments: const [outfit])
      ..deleteGarmentFailure = const ServerFailure(
        statusCode: 409,
        message: 'Someone is trying this outfit on right now.',
      );
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');

    final first = await notifier.deleteGarment(outfit);
    expect(first, isA<ServerFailure>());
    expect((first as ServerFailure).statusCode, 409);
    expect(dock.garments, [outfit], reason: 'nothing removed on a refusal');
    expect(notifier.state.session.dockGarments, [outfit]);

    final second = await notifier.deleteGarment(outfit, force: true);
    expect(second, isNull);
    expect(dock.deleteGarmentCalls.map((c) => c.force), [false, true]);
    expect(notifier.state.session.dockGarments, isEmpty,
        reason: 'the list refreshes after a successful delete');
  });

  test("a merchant's deleted result is deleted on the server, not just here",
      () async {
    // The dock is shared. A result removed only on this phone stays on every
    // other device the shop has open, and comes back here at the next refresh.
    await _signInVendor();
    final docked = DockPhoto(id: 'dp-9', imageUrl: 'https://cdn/dp9.jpg');
    final repo = _FakeRepo();
    final dock = _FakeDock(photos: [docked]);
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    await notifier.switchDockPhoto(docked);
    await notifier.generate();

    final shown = (notifier.state as TryonSuccess).current;
    await notifier.deleteResult(shown);

    expect(dock.deletedResults, [shown.generationId]);
  });

  test('a guest deletes results only on this device', () async {
    // There is no shared dock to tell, and nothing on the server to remove.
    final repo = _FakeRepo();
    final dock = _FakeDock();
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    notifier.selectFile(File('/tmp/selfie.jpg'));
    await notifier.generate();

    await notifier.deleteResult((notifier.state as TryonSuccess).current);

    expect(dock.deletedResults, isEmpty);
    expect(notifier.state, isA<TryonInitial>());
  });

  test('removing a photo someone else is using reports it, then forces',
      () async {
    await _signInVendor();
    final docked = DockPhoto(id: 'dp-9', imageUrl: 'https://cdn/dp9.jpg');
    final repo = _FakeRepo();
    final dock = _FakeDock(photos: [docked])
      ..deletePhotoFailure = const ServerFailure(
        statusCode: 409,
        message: 'Someone is being fitted with this photo right now.',
      );
    final notifier = _notifier(repo, dock: dock);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    await notifier.switchDockPhoto(docked);

    final first = await notifier.deletePhoto(docked);
    expect((first as ServerFailure).statusCode, 409);
    expect(dock.photos, [docked], reason: 'nothing removed on a refusal');

    final second = await notifier.deletePhoto(docked, force: true);
    expect(second, isNull);
    expect(dock.deletePhotoCalls.map((c) => c.force), [false, true]);
    // The photo on the canvas went with it; offering "Regenerate" against a
    // photo the server has dropped would only fail.
    expect(notifier.state.session.hasSelfie, isFalse);
    expect(notifier.state.session.dockPhotos, isEmpty);
  });

  test('a guest keeps the old order: the pipeline uploads, and no dock id is sent',
      () async {
    final repo = _FakeRepo();
    final notifier = _notifier(repo);
    await notifier.open(garmentUrl: 'https://cdn/garment.jpg');
    notifier.selectFile(File('/tmp/selfie.jpg'));

    await notifier.generate();

    expect(notifier.state, isA<TryonSuccess>());
    expect(_log, ['upload', 'execute']);
    expect(repo.lastDockPhotoId, isNull);
  });
}
