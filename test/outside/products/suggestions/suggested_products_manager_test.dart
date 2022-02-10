import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/products/suggestions/_radius_products_suggestions_manager.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map_full.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:test/test.dart';

import '../../../z_fakes/fake_off_shops_manager.dart';
import '../../../z_fakes/fake_settings.dart';
import '../../../z_fakes/fake_shops_manager.dart';

// ignore_for_file: cancel_subscriptions

void main() {
  late FakeShopsManager shopsManager;
  late FakeOffShopsManager offShopsManager;
  late ProductsAtShopsExtraPropertiesManager productsExtraProperties;
  late _FakeRadiusProductsSuggestionsManager radiusSuggestionsManager;
  late FakeSettings settings;

  late SuggestedProductsManager suggestedProductsManager;

  setUp(() async {
    shopsManager = FakeShopsManager();
    offShopsManager = FakeOffShopsManager();
    productsExtraProperties =
        ProductsAtShopsExtraPropertiesManager(MapExtraPropertiesCacher());
    radiusSuggestionsManager = _FakeRadiusProductsSuggestionsManager();
    settings = FakeSettings();
    suggestedProductsManager = SuggestedProductsManager(
        shopsManager, offShopsManager, productsExtraProperties, settings,
        radiusManager: radiusSuggestionsManager);
  });

  test('getSuggestedBarcodes - by OFF', () async {
    final center = Coord(
      lat: 10,
      lon: 10,
    );
    final offShops = [
      OffShop((e) => e
        ..id = 'spar'
        ..name = 'Spar'
        ..productsCount = 2
        ..country = 'ru'),
      OffShop((e) => e
        ..id = 'auchan'
        ..name = 'Auchan'
        ..productsCount = 2
        ..country = 'ru'),
      OffShop((e) => e
        ..id = 'groceries'
        ..name = 'Groceries'
        ..productsCount = 2
        ..country = 'ru'),
    ];
    final allSuggestions = {
      offShops[0]: ['123'],
      offShops[1]: [
        '124',
        '125',
      ],
      offShops[2]: [
        '126',
        '127',
        '128',
      ],
    };
    offShopsManager.setSuggestedBarcodes(allSuggestions);

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Auchan'))),
    ];

    var suggestionsRes = await suggestedProductsManager
        .getSuggestedBarcodesByOFFMap([shops[0]], center, 'ru');
    var suggestions = suggestionsRes.unwrap();
    expect(
        suggestions.equals(SuggestedBarcodesMap(
            {shops[0].osmUID: allSuggestions[offShops[0]]!})),
        isTrue);

    suggestionsRes = await suggestedProductsManager
        .getSuggestedBarcodesByOFFMap(shops, center, 'ru');
    suggestions = suggestionsRes.unwrap();
    expect(
        suggestions.equals(SuggestedBarcodesMap({
          shops[0].osmUID: allSuggestions[offShops[0]]!,
          shops[1].osmUID: allSuggestions[offShops[1]]!,
        })),
        isTrue);

    // But not if the settings disable the suggestions
    await settings.setEnableOFFProductsSuggestions(false);
    suggestionsRes = await suggestedProductsManager
        .getSuggestedBarcodesByOFFMap(shops, center, 'ru');
    suggestions = suggestionsRes.unwrap();
    expect(suggestions.asMap(), isEmpty);
  });

  test('getSuggestedBarcodes - by radius', () async {
    final center = Coord(
      lat: 10,
      lon: 10,
    );
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = center.lon
          ..latitude = center.lat
          ..name = 'Spar'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = center.lon
          ..latitude = center.lat
          ..name = 'Auchan'))),
    ];
    radiusSuggestionsManager.setSuggestionsFor(shops[0], ['123', '345']);
    radiusSuggestionsManager.setSuggestionsFor(shops[1], ['567', '789']);

    var result = await suggestedProductsManager.getSuggestedBarcodesByRadiusMap(
        shops, center, 'ru');
    expect(
        result.unwrap().equals(SuggestedBarcodesMap({
              OsmUID.parse('1:1'): ['123', '345'],
              OsmUID.parse('1:2'): ['567', '789'],
            })),
        isTrue);

    // But not if the settings disable the suggestions
    await settings.setEnableRadiusProductsSuggestions(false);
    result = await suggestedProductsManager.getSuggestedBarcodesByRadiusMap(
        shops, center, 'ru');
    expect(result.unwrap().asMap(), isEmpty);
  });

  Future<void> badSuggestionsAreNotSuggestedTest(
      {required ArgResCallback<List<String>, Future<OsmUID>> setUp,
      required ResCallback<Future<SuggestedBarcodesMap>>
          getSuggestions}) async {
    final osmUID = await setUp.call(['123', '124', '125']);

    // '123' is a good suggestion
    await productsExtraProperties.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, osmUID, '123', false);
    // '124' is a bad suggestion
    await productsExtraProperties.setBoolProperty(
        ProductAtShopExtraPropertyType.BAD_SUGGESTION, osmUID, '124', true);
    // property for '125' has a different type
    await productsExtraProperties.setBoolProperty(
        ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE,
        osmUID,
        '125',
        true);

    final suggestions = await getSuggestions.call();
    expect(
        suggestions.equals(SuggestedBarcodesMap({
          osmUID: ['123', '125']
        })),
        isTrue);
  }

  test('getSuggestedBarcodes by OFF - bad suggestions are not suggested',
      () async {
    final center = Coord(
      lat: 10,
      lon: 10,
    );
    final offShops = [
      OffShop((e) => e
        ..id = 'spar'
        ..name = 'Spar'
        ..productsCount = 2
        ..country = 'ru'),
    ];
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar'))),
    ];
    await badSuggestionsAreNotSuggestedTest(setUp: (suggestions) async {
      final allSuggestions = {
        offShops[0]: suggestions,
      };
      offShopsManager.setSuggestedBarcodes(allSuggestions);
      return shops[0].osmUID;
    }, getSuggestions: () async {
      final res = await suggestedProductsManager.getSuggestedBarcodesByOFFMap(
          shops, center, 'ru');
      return res.unwrap();
    });
  });

  test('getSuggestedBarcodes by radius - bad suggestions are not suggested',
      () async {
    final center = Coord(
      lat: 10,
      lon: 10,
    );
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = center.lon
          ..latitude = center.lat
          ..name = 'Spar'))),
    ];
    await badSuggestionsAreNotSuggestedTest(setUp: (suggestions) async {
      radiusSuggestionsManager.setSuggestionsFor(shops[0], suggestions);
      return shops[0].osmUID;
    }, getSuggestions: () async {
      final res = await suggestedProductsManager
          .getSuggestedBarcodesByRadiusMap(shops, center, 'ru');
      return res.unwrap();
    });
  });

  Future<void> getSuggestionsCanBeCanceledTest({
    required ArgCallback<Map<Shop, List<String>>> setUpSuggestions,
    required ArgResCallback<List<Shop>, SuggestionsStream> getSuggestionsStream,
  }) async {
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Spar'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 10
          ..latitude = 10
          ..name = 'Auchan'))),
    ];
    setUpSuggestions({
      shops[0]: ['123'],
      shops[1]: ['456'],
    });

    var stream = getSuggestionsStream.call(shops).asBroadcastStream();
    var calls = 0;
    StreamSubscription? subs;
    subs = stream.listen((event) {
      // Cancel the stream on first event
      subs!.cancel();
      calls += 1;
    });

    // Let's exhaust the stream
    await for (final _ in stream) {}
    // And check calls count
    expect(calls, equals(1));

    // Now let's do it all again, this time without
    // cancellation.

    stream = getSuggestionsStream.call(shops).asBroadcastStream();
    calls = 0;
    subs = stream.listen((event) {
      calls += 1;
    });
    // Let's exhaust the stream
    await for (final _ in stream) {}
    // And check calls count
    expect(calls, equals(2));
  }

  test('getSuggestedBarcodes by OFF - can be canceled', () async {
    final center = Coord(
      lat: 10,
      lon: 10,
    );
    await getSuggestionsCanBeCanceledTest(setUpSuggestions: (suggestions) {
      final offSuggestions = <OffShop, List<String>>{};
      for (final entry in suggestions.entries) {
        final shop = entry.key;
        final offShop = OffShop((e) => e
          ..id = shop.name.toLowerCase()
          ..name = shop.name
          ..productsCount = 2
          ..country = 'ru');
        offSuggestions[offShop] = entry.value;
      }
      offShopsManager.setSuggestedBarcodes(offSuggestions);
    }, getSuggestionsStream: (shops) {
      return suggestedProductsManager.getSuggestedBarcodes(shops, center, 'ru',
          types: {SuggestionType.OFF});
    });
  });

  test('getSuggestedBarcodes by radius - can be canceled', () async {
    Coord? center;
    await getSuggestionsCanBeCanceledTest(setUpSuggestions: (suggestions) {
      center = suggestions.keys.first.coord;
      for (final entry in suggestions.entries) {
        radiusSuggestionsManager.setSuggestionsFor(entry.key, entry.value);
      }
    }, getSuggestionsStream: (shops) {
      return suggestedProductsManager.getSuggestedBarcodes(shops, center!, 'ru',
          types: {SuggestionType.RADIUS});
    });
  });

  test('getSuggestedBarcodes', () async {
    final offShops = [
      OffShop((e) => e
        ..id = 'spar'
        ..name = 'Spar'
        ..productsCount = 2
        ..country = 'ru'),
      OffShop((e) => e
        ..id = 'auchan'
        ..name = 'Auchan'
        ..productsCount = 2
        ..country = 'ru'),
    ];
    final offSuggestions = {
      offShops[0]: ['123'],
      offShops[1]: ['345'],
    };
    offShopsManager.setSuggestedBarcodes(offSuggestions);

    final center = Coord(
      lat: 10,
      lon: 10,
    );
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = center.lon
          ..latitude = center.lat
          ..name = 'Spar'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = center.lon
          ..latitude = center.lat
          ..name = 'Auchan'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:3')
          ..longitude = center.lon
          ..latitude = center.lat
          ..name = '5ka'))),
    ];
    radiusSuggestionsManager.setSuggestionsFor(shops[1], ['567']);
    radiusSuggestionsManager.setSuggestionsFor(shops[2], ['789']);

    final allSuggestions = await suggestedProductsManager
        .getSuggestedBarcodesMap(shops, center, 'ru');

    final expected = SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: SuggestedBarcodesMap({
        shops[1].osmUID: ['567'],
        shops[2].osmUID: ['789'],
      }),
      SuggestionType.OFF: SuggestedBarcodesMap({
        shops[0].osmUID: ['123'],
        shops[1].osmUID: ['345'],
      }),
    });

    expect(allSuggestions.unwrap().equals(expected), isTrue);
  });

  test('getAllSuggestedBarcodes - can be canceled', () async {
    Coord? center;
    await getSuggestionsCanBeCanceledTest(setUpSuggestions: (suggestions) {
      expect(suggestions.length, greaterThan(1));
      final firstShop = suggestions.keys.first;
      final otherShops = suggestions.keys.toList().sublist(1);
      center = firstShop.coord;

      // OFF suggestions
      final offShop = OffShop((e) => e
        ..id = firstShop.name.toLowerCase()
        ..name = firstShop.name
        ..productsCount = 2
        ..country = 'ru');
      final offSuggestions = {offShop: suggestions[firstShop]!};
      offShopsManager.setSuggestedBarcodes(offSuggestions);

      // Radius suggestions
      for (final shop in otherShops) {
        radiusSuggestionsManager.setSuggestionsFor(shop, suggestions[shop]!);
      }
    }, getSuggestionsStream: (shops) {
      return suggestedProductsManager.getSuggestedBarcodes(
          shops, center!, 'ru');
    });
  });
}

class _FakeRadiusProductsSuggestionsManager
    implements RadiusProductsSuggestionsManager {
  final _suggestions = <Shop, List<String>>{};

  void setSuggestionsFor(Shop shop, List<String> barcodes) {
    _suggestions[shop] = barcodes;
  }

  @override
  Future<Map<Shop, List<String>>> getSuggestedBarcodesByRadius(
      Coord center, Iterable<Shop> shops) async {
    final result = <Shop, List<String>>{};
    for (final shop in shops) {
      final barcodes = _suggestions[shop];
      if (barcodes != null) {
        result[shop] = barcodes;
      }
    }
    return result;
  }
}

extension on SuggestedProductsManager {
  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesByRadiusMap(
          Iterable<Shop> shops, Coord center, String countryCode) async {
    return await getSuggestedBarcodesForType(
        SuggestionType.RADIUS, shops, center, countryCode);
  }

  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesByOFFMap(
          Iterable<Shop> shops, Coord center, String countryCode) async {
    return await getSuggestedBarcodesForType(
        SuggestionType.OFF, shops, center, countryCode);
  }

  Future<Result<SuggestedBarcodesMap, SuggestedProductsManagerError>>
      getSuggestedBarcodesForType(SuggestionType type, Iterable<Shop> shops,
          Coord center, String countryCode) async {
    final mapFullRes = await getSuggestedBarcodesMap(shops, center, countryCode,
        types: {type});
    if (mapFullRes.isErr) {
      return Err(mapFullRes.unwrapErr());
    }
    final mapFull = mapFullRes.unwrap();
    return Ok(mapFull[type] ?? SuggestedBarcodesMap({}));
  }
}
