import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/news/news_data_response.dart';

const REQUEST_NEWS_CMD = 'news_data';

extension BackendExt on Backend {
  Future<Result<NewsDataResponse, BackendError>> requestNews(
          CoordsBounds bounds,
          {required int page}) =>
      executeCmd(_RequestNewsCmd(bounds, page));
}

class _RequestNewsCmd extends BackendCmd<NewsDataResponse> {
  final CoordsBounds bounds;
  final int page;
  _RequestNewsCmd(this.bounds, this.page);

  @override
  Future<Result<NewsDataResponse, BackendError>> execute() async {
    final jsonRes = await backendGetJson('/$REQUEST_NEWS_CMD/', {
      'north': '${bounds.north}',
      'south': '${bounds.south}',
      'west': '${bounds.west}',
      'east': '${bounds.east}',
      'page': '$page'
    });
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    try {
      return Ok(NewsDataResponse.fromJson(json)!);
    } catch (e) {
      Log.w('Invalid news_data response: $json', ex: e);
      return Err(BackendError.invalidDecodedJson(json));
    }
  }
}
