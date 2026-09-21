import 'package:tryon2buy/core/errors/exceptions.dart';
import 'package:tryon2buy/core/errors/failures.dart';
import 'package:tryon2buy/core/utils/result.dart';

import '../../domain/entities/dock_garment.dart';
import '../../domain/entities/dock_photo.dart';
import '../../domain/repositories/i_dock_repository.dart';
import '../datasources/dock_remote_data_source.dart';
import '../models/dock_garment_dto.dart';
import '../models/dock_photo_dto.dart';

/// Concrete implementation of [IDockRepository] backed by the dock HTTP API.
///
/// This is the ONLY place where raw exceptions from the dock data source
/// get translated into domain [Failure] types.
class DockRepositoryImpl implements IDockRepository {
  final DockRemoteDataSource _remote;

  const DockRepositoryImpl(this._remote);

  @override
  Future<Result<List<DockPhoto>>> listPhotos() async {
    return _guard(() async {
      final json = await _remote.listPhotos();
      final rawPhotos = json['photos'] as List<dynamic>? ?? const [];
      return rawPhotos
          .whereType<Map<String, dynamic>>()
          .map(DockPhotoDto.fromJson)
          .toList();
    });
  }

  @override
  Future<Result<DockPhoto>> addPhoto(String imageUrl) async {
    return _guard(() async {
      final json = await _remote.addPhoto(imageUrl);
      return DockPhotoDto.fromJson(json);
    });
  }

  @override
  Future<Result<DockPhoto>> activatePhoto(String photoId) async {
    return _guard(() async {
      final json = await _remote.activatePhoto(photoId);
      return DockPhotoDto.fromJson(json);
    });
  }

  @override
  Future<Result<void>> deactivateAll() async {
    return _guard(() async {
      await _remote.deactivateAll();
    });
  }

  @override
  Future<Result<void>> touchPhoto(String photoId) async {
    return _guard(() async {
      await _remote.touchPhoto(photoId);
    });
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {bool force = false}) async {
    return _guard(() async {
      final json = await _remote.deletePhoto(photoId, force: force);
      if (json['inUse'] == true) {
        throw const ServerException(
          statusCode: 409,
          message: 'Someone is being fitted with this photo right now.',
        );
      }
    });
  }

  @override
  Future<Result<List<DockGarment>>> listGarments() async {
    return _guard(() async {
      final json = await _remote.listGarments();
      final rawGarments = json['garments'] as List<dynamic>? ?? const [];
      return rawGarments
          .whereType<Map<String, dynamic>>()
          .map(DockGarmentDto.fromJson)
          .toList();
    });
  }

  @override
  Future<Result<void>> touchGarment(String garmentId) async {
    return _guard(() async {
      await _remote.touchGarment(garmentId);
    });
  }

  @override
  Future<Result<void>> deleteGarment(
    String garmentId, {
    bool force = false,
  }) async {
    return _guard(() async {
      final json = await _remote.deleteGarment(garmentId, force: force);
      if (json['inUse'] == true) {
        throw const ServerException(
          statusCode: 409,
          message: 'Someone is trying this outfit on right now.',
        );
      }
    });
  }

  @override
  Future<Result<void>> deleteResult(String resultId) async {
    return _guard(() async {
      await _remote.deleteResult(resultId);
    });
  }

  @override
  Future<Result<void>> clearDock() async {
    return _guard(() async {
      await _remote.clearDock();
    });
  }

  // ─── Exception → Failure Mapping ─────────────────────────────────

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      final data = await call();
      return Success(data);
    } on NetworkException {
      return const Fail(NetworkFailure());
    } on RequestTimeoutException {
      return const Fail(TimeoutFailure());
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return const Fail(AuthTokenExpiredFailure());
      }
      return Fail(ServerFailure(statusCode: e.statusCode, message: e.message));
    } catch (e) {
      return Fail(UnknownFailure(e.toString()));
    }
  }
}
