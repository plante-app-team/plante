import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

void main() {
  final aShop = Shop((e) => e
    ..osmShop.replace(OsmShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..longitude = 10
      ..latitude = 10
      ..name = 'Spar'))
    ..backendShop.replace(BackendShop((e) => e
      ..osmUID = OsmUID.parse('1:1')
      ..productsCount = 2)));
  final products = [
    ProductLangSlice((v) => v
      ..barcode = '123'
      ..name = 'Apple'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..ingredientsText = 'Water, salt, sugar').productForTests(),
    ProductLangSlice((v) => v
      ..barcode = '124'
      ..name = 'Pineapple'
      ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..ingredientsText = 'Water, salt, sugar').productForTests(),
  ];
  final productsLastSeen = {
    products[0]: DateTime(2012, 1, 1),
    products[1]: DateTime(2011, 2, 2),
  };
  final productsLastSeenSecs = productsLastSeen.map((key, value) =>
      MapEntry(key.barcode, (value.millisecondsSinceEpoch / 1000).round()));
  final range = ShopProductRange((e) => e
    ..shop.replace(aShop)
    ..products.addAll(products)
    ..productsLastSeenSecsUtc.addAll(productsLastSeenSecs));

  setUp(() async {});

  test('rebuilding without a product', () {
    expect(range.products.toList(), equals(products));
    expect(range.productsLastSeenSecsUtc.toMap(), equals(productsLastSeenSecs));

    final productsCopy = range.products.toList();
    final lastSeenCopy = range.productsLastSeenSecsUtc.toMap();
    productsCopy.removeWhere((e) => e.barcode == products.first.barcode);
    lastSeenCopy.remove(products.first.barcode);

    final result = range.rebuildWithoutProduct(products.first.barcode);
    expect(result.products.toList(), equals(productsCopy));
    expect(result.productsLastSeenSecsUtc.toMap(), equals(lastSeenCopy));
  });

  test('rebuilding with a new product', () {
    expect(range.products.toList(), equals(products));
    expect(range.productsLastSeenSecsUtc.toMap(), equals(productsLastSeenSecs));

    final newProduct = ProductLangSlice((v) => v
      ..barcode = '100500'
      ..name = 'New product'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts).productForTests();
    final productsCopy = range.products.toList();
    final lastSeenCopy = range.productsLastSeenSecsUtc.toMap();
    productsCopy.add(newProduct);
    final now = DateTime.now().secondsSinceEpoch;
    lastSeenCopy[newProduct.barcode] = now;

    final result = range.rebuildWithProduct(newProduct, now);
    expect(result.products.toList(), equals(productsCopy));
    expect(result.productsLastSeenSecsUtc.toMap(), equals(lastSeenCopy));
  });

  test('rebuilding with an old product', () {
    expect(range.products.toList(), equals(products));
    expect(range.productsLastSeenSecsUtc.toMap(), equals(productsLastSeenSecs));

    final oldProduct = products.first;
    final lastSeenCopy = range.productsLastSeenSecsUtc.toMap();
    final now = DateTime.now().secondsSinceEpoch;
    lastSeenCopy[oldProduct.barcode] = now;

    final result = range.rebuildWithProduct(oldProduct, now);
    expect(result.products.toSet(), equals(range.products.toSet()));
    expect(result.productsLastSeenSecsUtc.toMap(), equals(lastSeenCopy));
  });
}
