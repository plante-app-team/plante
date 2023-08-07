import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/backend/cmds/request_news_cmd.dart';
import 'package:plante/outside/news/news_data_response.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/outside/news/news_piece.dart';

import '../../z_fakes/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late NewsFeedManager newsFeedManager;

  setUp(() async {
    backend = FakeBackend();
    newsFeedManager = NewsFeedManager(backend);
  });

  test('get news', () async {
    final newsPiece = NewsPiece((e) => e
      ..serverId = 3
      ..lat = 1.5
      ..lon = 1.6
      ..creatorUserId = 'user3'
      ..creationTimeSecs = 123454
      ..typeCode = 1
      ..data = MapBuilder({
        'barcode': JsonObject('654321'),
        'shop_uid': JsonObject('1:123321')
      }));
    backend.setResponse_testing(
        REQUEST_NEWS_CMD,
        jsonEncode(NewsDataResponse((e) => e
          ..lastPage = true
          ..results.add(newsPiece)).toJson()));

    expect(backend.getRequestsMatching_testing(REQUEST_NEWS_CMD), isEmpty);

    final result = await newsFeedManager.obtainNews(
        page: 1, center: Coord(lat: 1, lon: 2));

    final request = backend.getRequestsMatching_testing(REQUEST_NEWS_CMD).first;
    final requestedBounds = CoordsBounds(
        southwest: Coord(
            lat: double.parse(request.url.queryParameters['south']!),
            lon: double.parse(request.url.queryParameters['west']!)),
        northeast: Coord(
            lat: double.parse(request.url.queryParameters['north']!),
            lon: double.parse(request.url.queryParameters['east']!)));
    expect(result.unwrap(), equals([newsPiece]));
    expect(requestedBounds.center.lat, closeTo(1, 0.00001));
    expect(requestedBounds.center.lon, closeTo(2, 0.00001));
  });
}
