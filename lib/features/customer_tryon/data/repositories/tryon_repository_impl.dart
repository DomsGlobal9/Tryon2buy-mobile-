import 'dart:io';

import 'package:tryon2buy/core/errors/exceptions.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';
import '../../domain/entities/tryon_result.dart';
import '../../domain/repositories/i_tryon_repository.dart';
import '../datasources/tryon_remote_data_source.dart';

/// Concrete implementation of [ITryonRepository].
///
/// This is the ONLY place where raw exceptions from the data layer
/// get translated into domain [Failure] types. The contract ensures
/// the presentation layer never sees exceptions — only typed [Result]s.
class TryonRepositoryImpl implements ITryonRepository {
  final TryonRemoteDataSource _remote;

  const TryonRepositoryImpl(this._remote);

  @override
  Future<Result<String>> uploadSelfie(File imageFile) async {
    return _guard(() => _remote.uploadSelfie(imageFile));
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
    return _guard(() async {
      final dto = await _remote.generateTryon(
        garmentUrl: garmentUrl,
        humanImageUrl: humanImageUrl,
        mode: mode,
        parentGenerationId: parentGenerationId,
        category: category,
        targetFolder: targetFolder,
        dupattaStyleUrl: dupattaStyleUrl,
        dockPhotoId: dockPhotoId,
      );
      return dto.toEntity();
    });
  }

  @override
  Future<Result<String>> changeBackground({
    required String currentImageUrl,
    required String backgroundId,
    String? generationId,
  }) async {
    return _guard(() => _remote.changeBackground(
          imageUrl: currentImageUrl,
          backgroundId: backgroundId,
          generationId: generationId,
        ));
  }

  @override
  Future<Result<String>> modifyOutfitStyle({
    required String currentImageUrl,
    required String modificationType,
    String? generationId,
  }) async {
    return _guard(() => _remote.modifyOutfit(
          imageUrl: currentImageUrl,
          modificationType: modificationType,
          generationId: generationId,
        ));
  }

  @override
  Future<Result<TryonResult>> fetchGeneration(String id) async {
    return _guard(() async {
      final dto = await _remote.fetchGeneration(id);
      return dto.toEntity();
    });
  }

  // ─── Exception → Failure Mapping ─────────────────────────────────

  /// Wraps any data-source call and catches exceptions → [Failure].
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      final data = await call();
      return Success(data);
    } on NetworkException {
      return const Fail(NetworkFailure());
    } on RequestTimeoutException {
      return const Fail(TimeoutFailure());
    } on ImageException catch (e) {
      return Fail(ImageProcessingFailure(e.message));
    } on ServerException catch (e) {
      return Fail(_mapServerException(e));
    } catch (e) {
      return Fail(UnknownFailure(e.toString()));
    }
  }

  /// Inspect the [ServerException] for known business-error patterns.
  Failure _mapServerException(ServerException e) {
    // Business codes first: the guest quota arrives as a 401 too
    // (`GUEST_LIMIT_REACHED`) and must not read as a dead session.
    final body = e.rawBody ?? '';
    if (body.contains('INSUFFICIENT_CREDITS')) {
      return const InsufficientCreditsFailure();
    }
    if (body.contains('GUEST_LIMIT') || body.contains('guest limit')) {
      return const GuestLimitReachedFailure();
    }

    if (e.statusCode == 401) {
      return const AuthTokenExpiredFailure();
    }

    return ServerFailure(statusCode: e.statusCode, message: e.message);
  }
}
