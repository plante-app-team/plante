import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/osm_uid.dart';

@immutable
class FetchedShops {
  final Map<OsmUID, Shop> shops;
  final CoordsBounds shopsBounds;
  final Map<OsmUID, OsmShop> osmShops;
  final CoordsBounds osmShopsBounds;
  const FetchedShops(
      this.shops, this.shopsBounds, this.osmShops, this.osmShopsBounds);

  @override
  bool operator ==(Object other) {
    if (other is! FetchedShops) {
      return false;
    }
    return mapEquals(shops, other.shops) &&
        shopsBounds == other.shopsBounds &&
        mapEquals(osmShops, other.osmShops) &&
        osmShopsBounds == other.osmShopsBounds;
  }

  @override
  int get hashCode => hashValues(shopsBounds, osmShopsBounds);

  @override
  String toString() {
    return '''{
      "shops": $shops,
      "shopsBounds": $shopsBounds,
      "osmShops": $osmShops,
      "osmShopsBounds": $osmShopsBounds
      }
    ''';
  }
}
