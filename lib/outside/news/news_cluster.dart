import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/outside/news/news_piece.dart';
import 'package:plante/outside/news/news_piece_product_at_shop.dart';
import 'package:plante/outside/news/news_piece_type.dart';

part 'news_cluster.g.dart';

abstract class NewsCluster implements Built<NewsCluster, NewsClusterBuilder> {
  int get typeCode;
  String get authorId;
  BuiltList<NewsPiece> get newsPieces;

  NewsPieceType get type => newsPieceTypeFromCode(typeCode);
  String get authorName => newsPieces.first.creatorUserName;
  int get creationTimeSecs =>
      newsPieces.map((np) => np.creationTimeSecs).reduce(max);

  factory NewsCluster([void Function(NewsClusterBuilder) updates]) =
      _$NewsCluster;
  NewsCluster._();
  static Serializer<NewsCluster> get serializer => _$newsClusterSerializer;

  static List<NewsCluster> clustersFrom(List<NewsPiece> newsPieces) {
    final result = <NewsCluster>[];
    var clusterNews = <NewsPiece>[];

    for (final newsPiece in newsPieces) {
      if (clusterNews.isEmpty) {
        clusterNews = [newsPiece];
      } else if (_shouldCreateNewCluster(clusterNews, newsPiece)) {
        result.add(_formCluster(clusterNews));
        clusterNews = [newsPiece];
      } else if (newsPiece.type == NewsPieceType.PRODUCT_AT_SHOP &&
          _haveSameProduct(clusterNews, newsPiece)) {
        clusterNews.add(newsPiece);
      } else {
        result.add(_formCluster(clusterNews));
        clusterNews = [newsPiece];
      }
    }

    if (clusterNews.isNotEmpty) {
      result.add(_formCluster(clusterNews));
    }

    return result;
  }

  static bool _shouldCreateNewCluster(
      List<NewsPiece> clusterNews, NewsPiece newsPiece) {
    return newsPiece.creatorUserId != clusterNews.first.creatorUserId ||
        newsPiece.type != clusterNews.first.type ||
        newsPiece.type == NewsPieceType.UNKNOWN;
  }

  static bool _haveSameProduct(
      List<NewsPiece> clusterNews, NewsPiece newsPiece) {
    final newsPieceTypedData = newsPiece.typedData as NewsPieceProductAtShop;
    final clusterFirstTypedData =
        clusterNews.first.typedData as NewsPieceProductAtShop;
    return newsPieceTypedData.barcode == clusterFirstTypedData.barcode;
  }

  static NewsCluster _formCluster(List<NewsPiece> clusterNews) {
    return NewsCluster((e) => e
      ..typeCode = clusterNews.first.typeCode
      ..authorId = clusterNews.first.creatorUserId
      ..newsPieces = ListBuilder(clusterNews));
  }
}

extension NewsClusterList on List<NewsCluster> {
  List<NewsCluster> combineWith(List<NewsPiece> newsPieces) {
    final allNewsPieces = _unfold();
    allNewsPieces.addAll(newsPieces);
    return NewsCluster.clustersFrom(allNewsPieces);
  }

  List<NewsPiece> _unfold() {
    final result = <NewsPiece>[];
    for (final cluster in this) {
      result.addAll(cluster.newsPieces);
    }
    return result;
  }
}
