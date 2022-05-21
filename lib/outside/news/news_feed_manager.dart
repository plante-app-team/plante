import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/news/news_piece.dart';

class NewsFeedManager {
  static const REQUESTED_AREA_SIZE_KMS = 35.0;
  final Backend _backend;

  NewsFeedManager(this._backend);

  Future<Result<List<NewsPiece>, GeneralError>> obtainNews(
      {required int page, required Coord center}) async {
    final backendNewsRes = await _backend.requestNews(
        center.makeSquare(kmToGrad(REQUESTED_AREA_SIZE_KMS)),
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
