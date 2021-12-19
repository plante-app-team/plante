import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

@immutable
class FetchedShops {
  final Map<OsmUID, Shop> shops;
  final Map<OsmUID, List<String>> shopsBarcodes;
  final CoordsBounds shopsBounds;
  final Map<OsmUID, OsmShop> osmShops;
  final CoordsBounds osmShopsBounds;
  const FetchedShops(this.shops, this.shopsBarcodes, this.shopsBounds,
      this.osmShops, this.osmShopsBounds);

  @override
  bool operator ==(Object other) {
    if (other is! FetchedShops) {
      return false;
    }
    if (shopsBarcodes.length != other.shopsBarcodes.length) {
      return false;
    }
    for (final key in shopsBarcodes.keys) {
      final list1 = shopsBarcodes[key];
      final list2 = other.shopsBarcodes[key];
      if (list1 == null || list2 == null) {
        return false;
      }
      if (!listEquals(list1, list2)) {
        return false;
      }
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
      "shopsBarcodes": $shopsBarcodes,
      "shopsBounds": $shopsBounds,
      "osmShops": $osmShops,
      "osmShopsBounds": $osmShopsBounds
      }
    ''';
  }
}
