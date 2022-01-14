import 'dart:io';

import 'package:openfoodfacts/model/SearchResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/off/off_geo_helper.dart';
import 'package:plante/outside/off/off_vegan_barcodes_obtainer.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_address_obtainer.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_off_api.dart';

void main() {
  const defaultCountry = 'Belgium';
  final shops = [
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar1'))),
    Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:2')
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar2'))),
  ];

  late FakeOffApi offApi;
  late FakeAddressObtainer addressObtainer;
  late FakeAnalytics analytics;
  late OffGeoHelper geoHelper;

  setUp(() async {
    offApi = FakeOffApi();
    addressObtainer = FakeAddressObtainer();
    analytics = FakeAnalytics();
    geoHelper = OffGeoHelper(offApi, addressObtainer, analytics);
    addressObtainer
        .setDefaultResponse(OsmAddress((e) => e.country = defaultCountry));
  });

  test('simple good scenario', () async {
    expect(offApi.saveProductCalls_testing(), isEmpty);

    final result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    final products = offApi.saveProductCalls_testing();

    expect(products[0].barcode, equals('123'));
    expect(products[0].stores, equals(shops.map((e) => e.name).join(',')));
    expect(products[0].countries, equals('en:$defaultCountry'));
    expect(products[0].categories,
        equals(OffVeganBarcodesObtainer.CATEGORY_PLANT_BASED));
    expect(products[1].barcode, equals('234'));
    expect(products[1].stores, equals(shops.map((e) => e.name).join(',')));
    expect(products[1].countries, equals('en:$defaultCountry'));
    expect(products[1].categories,
        equals(OffVeganBarcodesObtainer.CATEGORY_PLANT_BASED));
  });

  test('analytics', () async {
    expect(analytics.allEvents(), isEmpty);

    await geoHelper.addGeodataToProducts(['123'], shops);
    expect(
        analytics.wasEventSent('add_geodata_to_off_product_success'), isTrue);
    expect(
        analytics.wasEventSent('add_geodata_to_off_product_failure'), isFalse);
    analytics.clearEvents();

    offApi.setSaveProductResponses_testing(
        (_) => off.Status(error: 'hello there'));

    await geoHelper.addGeodataToProducts(['123'], shops);
    expect(
        analytics.wasEventSent('add_geodata_to_off_product_success'), isFalse);
    expect(
        analytics.wasEventSent('add_geodata_to_off_product_failure'), isTrue);
  });

  test('OFF get products network error', () async {
    // OK yet
    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Not OK anymore
    offApi.setProductsListResponses_testing(
        (_) => throw const SocketException('oops'));
    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isErr, isTrue, reason: result.toString());
  });

  test('OFF null products', () async {
    // OK yet
    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Not OK anymore
    offApi.setProductsListResponses_testing(
        (_) => const off.SearchResult(products: null));
    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isErr, isTrue, reason: result.toString());
  });

  test('OFF no products', () async {
    // OK yet
    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Not OK anymore
    offApi.setProductsListResponses_testing(
        (_) => const off.SearchResult(products: []));
    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isErr, isTrue, reason: result.toString());
  });

  test('OFF save product network error', () async {
    // OK yet
    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Not OK anymore
    offApi.setSaveProductResponses_testing(
        (_) => throw const SocketException('oops'));
    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isErr, isTrue, reason: result.toString());
  });

  test('OFF save product other error', () async {
    // OK yet
    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Not OK anymore
    offApi.setSaveProductResponses_testing(
        (_) => off.Status(error: 'hello there'));
    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isErr, isTrue, reason: result.toString());
  });

  test('address is requested only once if 2 shops are close', () async {
    const closeDistanceMeters = OffGeoHelper.CLOSE_SHOPS_DISTANCE_METERS / 2;
    final closeDistance = kmToGrad(closeDistanceMeters / 1000);
    final coord1 = Coord(
      lat: 10,
      lon: 10,
    );
    final coord2 = Coord(
      lat: coord1.lat + closeDistance,
      lon: coord1.lon + closeDistance,
    );
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = coord1.lon
          ..latitude = coord1.lat
          ..name = 'Spar1'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = coord2.lon
          ..latitude = coord2.lat
          ..name = 'Spar2'))),
    ];

    expect(addressObtainer.recordedRequestsCount(), equals(0));

    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue);
    // Only 1 address request expected
    expect(addressObtainer.recordedRequestsCount(), equals(1));

    addressObtainer.resetRecordedRequests();
    expect(addressObtainer.recordedRequestsCount(), equals(0));

    // Now the second shop will be far away
    final coord3 = Coord(
      lat: coord1.lat + closeDistance * 10,
      lon: coord1.lon + closeDistance * 10,
    );
    shops[1] = shops[1].rebuildWith(coord: coord3);

    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue);
    // Now 2 address requests expected
    expect(addressObtainer.recordedRequestsCount(), equals(2));
  });

  test('address could not be obtained', () async {
    // OK yet
    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Not OK anymore
    addressObtainer.setDefaultResponseFull(Err(OpenStreetMapError.OTHER));
    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isErr, isTrue, reason: result.toString());
  });

  test('address without country is obtained', () async {
    // OK yet
    var result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Not OK anymore
    addressObtainer.setDefaultResponse(OsmAddress((e) => e.countryCode = 'ru'));
    result = await geoHelper.addGeodataToProducts(['123', '234'], shops);
    expect(result.isErr, isTrue, reason: result.toString());
  });

  test('EN lang code is used when address is obtained', () async {
    expect(addressObtainer.recordedRequests(), isEmpty);

    await geoHelper.addGeodataToProducts(['123', '234'], [shops.first]);

    expect(addressObtainer.recordedRequests(),
        equals([RecordedAddressRequest(shops.first.coord, LangCode.en.name)]));
  });

  test('countries duplicates are not inserted', () async {
    final defaultCountryLowercase = defaultCountry.toLowerCase();

    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            countries: 'Russia,$defaultCountryLowercase',
            countriesTags: ['Russia', defaultCountryLowercase],
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    final products = offApi.saveProductCalls_testing();
    expect(products[0].countries, equals('Russia,$defaultCountryLowercase'));
  });

  test('country name in "countries" is ignored', () async {
    addressObtainer
        .setDefaultResponse(OsmAddress((e) => e.country = 'Belgium'));

    // If "countries" has "Belgique" (French), but "countries_tags"
    // has "Belgium" - the latter is considered only
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            countries: 'Russia,Belgique',
            countriesTags: ['Russia', 'Belgium'],
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // The initial [countries] field is expected to be unchanged
    final products = offApi.saveProductCalls_testing();
    expect(products[0].countries, equals('Russia,Belgique'));
  });

  test('country names with lang prefixes are handled properly', () async {
    addressObtainer
        .setDefaultResponse(OsmAddress((e) => e.country = 'Belgium'));

    // If an existing country has a lang prefix, the new country
    // with same name handles it and is not added
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            countries: 'Russia,Belgium',
            countriesTags: ['en:Russia', 'en:Belgium'],
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // The initial [countries] field is expected to be unchanged
    final products = offApi.saveProductCalls_testing();
    expect(products[0].countries, equals('Russia,Belgium'));
  });

  test('product already had a few country names', () async {
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            countries: 'Russia,Belarus',
            countriesTags: ['Russia', 'Belarus'],
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // [defaultCountry] is expected to be added to the existing list of countries
    final products = offApi.saveProductCalls_testing();
    expect(products[0].countries, equals('Russia,Belarus,en:$defaultCountry'));
  });

  test('shops duplicates are not inserted', () async {
    final shopsStr = shops.map((e) => e.name).join(',');
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            stores: shopsStr,
          ));
    });

    var result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // The product already had the shops we were adding to it
    var products = offApi.saveProductCalls_testing();
    expect(products[0].stores, equals(shopsStr));

    offApi.clearSaveProductsCalls_testing();

    // Now let's make the existing shops different
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            stores: 'Auchan',
          ));
    });

    result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Now the product had a different shop - we expect our shops to be
    // added to it
    products = offApi.saveProductCalls_testing();
    expect(products[0].stores, equals('Auchan,$shopsStr'));
  });

  test('shops with whitespaces instead of names are ignored', () async {
    // Whitespace shops ('  ') are ignored

    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            stores: '   ',
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    final shopsStr = shops.map((e) => e.name).join(',');
    final products = offApi.saveProductCalls_testing();
    expect(products[0].stores, equals(shopsStr));
  });

  test('product is not sent to OFF if it is not changed', () async {
    final shopsStr = shops.map((e) => e.name).join(',');

    // The product already has all data we would expect
    // the geo helper to add.
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            countries: defaultCountry,
            countriesTags: [defaultCountry],
            categories: 'Plant-based foods',
            categoriesTags: [OffVeganBarcodesObtainer.CATEGORY_PLANT_BASED],
            stores: shopsStr,
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    expect(offApi.saveProductCalls_testing(), isEmpty);
  });

  test('product already had a few categories', () async {
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            categories: 'Pickles,Apples',
            categoriesTags: ['en:pickles', 'en:apples'],
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    final products = offApi.saveProductCalls_testing();
    expect(
        products[0].categories,
        equals(
            'Pickles,Apples,${OffVeganBarcodesObtainer.CATEGORY_PLANT_BASED}'));
  });

  test('product category duplicate is not inserted', () async {
    offApi.setProductsListResponsesSimple_testing((config) {
      return config.barcodes.map((e) => Product(
            barcode: e,
            categories: 'Pickles,Plant-based foods,Apples',
            categoriesTags: [
              'en:pickles',
              OffVeganBarcodesObtainer.CATEGORY_PLANT_BASED,
              'en:apples'
            ],
          ));
    });

    final result = await geoHelper.addGeodataToProducts(['123'], shops);
    expect(result.isOk, isTrue, reason: result.toString());

    // Initial categories have not changed
    final products = offApi.saveProductCalls_testing();
    expect(products[0].categories, equals('Pickles,Plant-based foods,Apples'));
    expect(
        products[0].categoriesTags,
        equals([
          'en:pickles',
          OffVeganBarcodesObtainer.CATEGORY_PLANT_BASED,
          'en:apples'
        ]));
  });
}
