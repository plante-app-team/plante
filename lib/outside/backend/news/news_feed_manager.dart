import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/news/news_piece.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

class NewsFeedManager {
  static const _REQUESTED_AREA_SIZE_KMS = 35.0;
  final Backend _backend;
  final LatestCameraPosStorage _cameraPosStorage;

  NewsFeedManager(this._backend, this._cameraPosStorage);

  Future<Result<List<NewsPiece>, GeneralError>> obtainNews(
      {required int page}) async {
    final pos = await _cameraPosStorage.get();
    if (pos == null) {
      Log.w('No camera position for some reason');
      return Ok(const []);
    }
    final backendNewsRes = await _backend.requestNews(
        pos.makeSquare(kmToGrad(_REQUESTED_AREA_SIZE_KMS)),
        page: page);
    if (backendNewsRes.isErr) {
      return Err(backendNewsRes.unwrapErr().toGeneral());
    }
    final backendNews = backendNewsRes.unwrap();
    final results = backendNews.results.toList();
    results.sort((a, b) => b.creationTimeSecs - a.creationTimeSecs);
    return Ok(results);
  }
}
