import 'dart:async';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_short_address.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/photos/photos_taker.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../z_fakes/fake_input_products_lang_storage.dart';
import '../../z_fakes/fake_products_at_shops_extra_properties_manager.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_shops_manager.dart';
import '../../z_fakes/fake_suggested_products_manager.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

class ShopProductRangePageTestCommons {
  final countryCode = CountryCode.FRANCE;

  late final FakeShopsManager shopsManager;
  late final FakeUserParamsController userParamsController;
  late final MockProductsManager productsManager;
  late final MockPermissionsManager permissionsManager;
  late final MockAddressObtainer addressObtainer;
  late final FakeCachingUserAddressPiecesObtainer userAddressObtainer;
  late final FakeProductsObtainer productsObtainer;
  late final FakeSuggestedProductsManager suggestedProductsManager;
  late final ProductsAtShopsExtraPropertiesManager productsExtraProperties;

  late final Shop aShop;

  late final List<Product> confirmedProducts;
  late final Map<Product, DateTime> confirmedProductsLastSeen;
  late final Map<String, int> confirmedProductsLastSeenSecs;
  late final ShopProductRange range;

  late final List<Product> suggestedProducts;

  late final OsmShortAddress address;
  late final FutureShortAddress readyAddress;

  ShopProductRangePageTestCommons._();

  static Future<ShopProductRangePageTestCommons> create() async {
    final result = ShopProductRangePageTestCommons._();
    await result._init();
    return result;
  }

  Future<void> _init() async {
    aShop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..longitude = 10
        ..latitude = 10
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = OsmUID.parse('1:1')
        ..productsCount = 1)));

    confirmedProducts = [
      ProductLangSlice((v) => v
        ..barcode = '123'
        ..name = 'Apple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.possible
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..imageIngredients =
            Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
      ProductLangSlice((v) => v
        ..barcode = '124'
        ..name = 'Pineapple'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..imageIngredients =
            Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
    ];
    confirmedProductsLastSeen = {
      confirmedProducts[0]: DateTime(2012, 1, 1),
      confirmedProducts[1]: DateTime(2011, 2, 2),
    };
    confirmedProductsLastSeenSecs = confirmedProductsLastSeen.map((key,
            value) =>
        MapEntry(key.barcode, (value.millisecondsSinceEpoch / 1000).round()));
    range = ShopProductRange((e) => e
      ..shop.replace(aShop)
      ..products.addAll(confirmedProducts)
      ..productsLastSeenSecsUtc.addAll(confirmedProductsLastSeenSecs));

    address = OsmShortAddress((e) => e.road = 'Broadway');
    readyAddress = Future.value(Ok(address));

    suggestedProducts = [
      ProductLangSlice((v) => v
        ..barcode = '321'
        ..name = 'Suggested Fruit Pie'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.possible
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..imageIngredients =
            Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
      ProductLangSlice((v) => v
        ..barcode = '320'
        ..name = 'Suggested Chickpea'
        ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..veganStatus = VegStatus.positive
        ..veganStatusSource = VegStatusSource.open_food_facts
        ..imageIngredients =
            Uri.file(File('./test/assets/img.jpg').absolute.path)
        ..ingredientsText = 'Water, salt, sugar').productForTests(),
    ];

    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());
    shopsManager = FakeShopsManager();
    GetIt.I.registerSingleton<ShopsManager>(shopsManager);
    userParamsController = FakeUserParamsController();
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    productsManager = MockProductsManager();
    GetIt.I.registerSingleton<ProductsManager>(productsManager);
    productsObtainer = FakeProductsObtainer();
    GetIt.I.registerSingleton<ProductsObtainer>(productsObtainer);
    permissionsManager = MockPermissionsManager();
    GetIt.I.registerSingleton<PermissionsManager>(permissionsManager);
    GetIt.I
        .registerSingleton<SysLangCodeHolder>(SysLangCodeHolder.inited('en'));
    GetIt.I
        .registerSingleton<ViewedProductsStorage>(MockViewedProductsStorage());
    GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(MockRouteObserver());
    addressObtainer = MockAddressObtainer();
    GetIt.I.registerSingleton<AddressObtainer>(addressObtainer);
    final photosTaker = MockPhotosTaker();
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);
    GetIt.I.registerSingleton<InputProductsLangStorage>(
        FakeInputProductsLangStorage.fromCode(LangCode.en));
    GetIt.I.registerSingleton<UserLangsManager>(
        FakeUserLangsManager([LangCode.en]));
    GetIt.I.registerSingleton<Backend>(MockBackend());
    suggestedProductsManager = FakeSuggestedProductsManager();
    GetIt.I
        .registerSingleton<SuggestedProductsManager>(suggestedProductsManager);
    when(photosTaker.retrieveLostPhoto(any)).thenAnswer((_) async => null);
    productsExtraProperties = FakeProductsAtShopsExtraPropertiesManager();
    GetIt.I.registerSingleton<ProductsAtShopsExtraPropertiesManager>(
        productsExtraProperties);
    userAddressObtainer = FakeCachingUserAddressPiecesObtainer();
    userAddressObtainer.setResultFor(UserAddressType.CAMERA_LOCATION,
        UserAddressPiece.COUNTRY_CODE, countryCode);
    GetIt.I.registerSingleton<CachingUserAddressPiecesObtainer>(
        userAddressObtainer);

    final params = UserParams((v) => v.name = 'Bob');
    await userParamsController.setUserParams(params);

    shopsManager.setShopRange(aShop.osmUID, Ok(range));
    productsObtainer.addKnownProducts(confirmedProducts);
    productsObtainer.addKnownProducts(suggestedProducts);
    suggestedProductsManager.setSuggestionsForShop(aShop.osmUID,
        suggestedProducts.map((e) => e.barcode), SuggestionType.OFF);
    when(permissionsManager.status(any))
        .thenAnswer((_) async => PermissionState.granted);
    when(productsManager.createUpdateProduct(any))
        .thenAnswer((invc) async => Ok(invc.positionalArguments[0] as Product));
    when(addressObtainer.addressOfShop(any)).thenAnswer((_) => readyAddress);
  }

  void setSuggestedProducts(Map<SuggestionType, List<Product>> products) {
    suggestedProductsManager.clearAllSuggestions();
    for (final entry in products.entries) {
      productsObtainer.addKnownProducts(entry.value);
      suggestedProductsManager.setSuggestionsForShop(
          aShop.osmUID, entry.value.map((e) => e.barcode), entry.key);
    }
  }

  void setConfirmedProducts(List<Product> products,
      [Map<String, int>? lastSeen]) {
    productsObtainer.addKnownProducts(products);
    shopsManager.setShopRange(aShop.osmUID, Ok(range.rebuild((e) {
      e.products = ListBuilder(products);
      if (lastSeen != null) {
        e.productsLastSeenSecsUtc = MapBuilder(lastSeen);
      }
    })));
  }
}
