import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:plante/outside/news/news_cluster.dart';
import 'package:plante/outside/news/news_piece.dart';
import 'package:plante/outside/news/news_piece_type.dart';
import 'package:test/test.dart';

void main() {
  test('news pieces with same author and same product are merged', () async {
    final newsPieces = [
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user1'),
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user2'),
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user2'),
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user1'),
    ];

    final expectedClusters = [
      _createNewsCluster([newsPieces[0]]),
      _createNewsCluster([newsPieces[1], newsPieces[2]]),
      _createNewsCluster([newsPieces[3]]),
    ];

    expect(NewsCluster.clustersFrom(newsPieces), equals(expectedClusters));
  });

  test('news pieces with same author but different products are not merged',
      () async {
    final newsPieces = [
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user1'),
      _createProductAtShopNewsPiece(barcode: '124', creatorId: 'user1'),
    ];

    final expectedClusters = [
      _createNewsCluster([newsPieces[0]]),
      _createNewsCluster([newsPieces[1]]),
    ];

    expect(NewsCluster.clustersFrom(newsPieces), equals(expectedClusters));
  });

  test('news pieces with same product but different authors are not merged',
      () async {
    final newsPieces = [
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user1'),
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user2'),
    ];

    final expectedClusters = [
      _createNewsCluster([newsPieces[0]]),
      _createNewsCluster([newsPieces[1]]),
    ];

    expect(NewsCluster.clustersFrom(newsPieces), equals(expectedClusters));
  });

  test(
      'combining clusters with new news pieces updates the last cluster when product and author match',
      () async {
    final newsPieces1 = [
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user1'),
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user2'),
    ];
    final initialClusters = [
      _createNewsCluster([newsPieces1[0]]),
      _createNewsCluster([newsPieces1[1]]),
    ];

    final newsPieces2 = [
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user2'),
      _createProductAtShopNewsPiece(barcode: '123', creatorId: 'user1'),
    ];

    final expectedClusters = [
      _createNewsCluster([newsPieces1[0]]),
      _createNewsCluster([newsPieces1[1], newsPieces2[0]]),
      _createNewsCluster([newsPieces2[1]]),
    ];

    expect(initialClusters.combineWith(newsPieces2), equals(expectedClusters));
  });

  test('creation time is used from the latest news', () async {
    final newsPieces = [
      _createProductAtShopNewsPiece(
          barcode: '123', creatorId: 'user1', creationTimeSecs: 10),
      _createProductAtShopNewsPiece(
          barcode: '123', creatorId: 'user1', creationTimeSecs: 30),
      _createProductAtShopNewsPiece(
          barcode: '123', creatorId: 'user1', creationTimeSecs: 20),
    ];

    final cluster = NewsCluster.clustersFrom(newsPieces).first;
    expect(cluster.creationTimeSecs, equals(30));
  });
}

NewsPiece _createProductAtShopNewsPiece(
    {required String barcode,
    required String creatorId,
    int creationTimeSecs = 123454}) {
  return NewsPiece((e) => e
    ..serverId = 1
    ..lat = 1.5
    ..lon = 1.6
    ..creatorUserId = creatorId
    ..creationTimeSecs = creationTimeSecs
    ..typeCode = NewsPieceType.PRODUCT_AT_SHOP.persistentCode
    ..data = MapBuilder(
        {'barcode': JsonObject(barcode), 'shop_uid': JsonObject('1:123321')}));
}

NewsCluster _createNewsCluster(List<NewsPiece> newsPieces) {
  return NewsCluster((e) => e
    ..typeCode = newsPieces.first.typeCode
    ..authorId = newsPieces.first.creatorUserId
    ..newsPieces = ListBuilder(newsPieces));
}
