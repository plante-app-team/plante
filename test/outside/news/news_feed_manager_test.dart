import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/news/news_data_response.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/outside/news/news_piece.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockBackend backend;
  late NewsFeedManager newsFeedManager;

  setUp(() async {
    backend = MockBackend();
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
    when(backend.requestNews(any, page: anyNamed('page')))
        .thenAnswer((_) async => Ok(NewsDataResponse((e) => e
          ..lastPage = true
          ..results.add(newsPiece))));

    verifyNever(backend.requestNews(any));

    final result = await newsFeedManager.obtainNews(
        page: 1, center: Coord(lat: 1, lon: 2));
    final requestedBounds =
        verify(backend.requestNews(captureAny, page: anyNamed('page')))
            .captured
            .first as CoordsBounds;

    expect(result.unwrap(), equals([newsPiece]));
    expect(requestedBounds.center, equals(Coord(lat: 1, lon: 2)));
  });
}
