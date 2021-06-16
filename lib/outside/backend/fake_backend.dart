import 'dart:math';

import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';

class FakeBackend implements Backend {
  final Settings _settings;

  FakeBackend(this._settings);

  UserParams _userParams = UserParams((e) => e
    ..backendId = DateTime.now().millisecondsSinceEpoch.toString()
    ..backendClientToken = 'token'
    ..name = 'Testing User for Fake Backend'
    ..eatsMilk = false
    ..eatsEggs = false
    ..eatsHoney = false
    ..userGroup = 2);
  final _fakeShops = <String, BackendProductsAtShop>{};

  Future<void> _delay() async {
    if (await _settings.testingBackendsQuickAnswers()) {
      await Future.delayed(const Duration(milliseconds: 1));
    } else {
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  int _nowSecs() {
    return (DateTime.now().millisecondsSinceEpoch / 1000).round();
  }

  @override
  void addObserver(BackendObserver observer) {
    // No backend errors on fake backend - nothing to observe
  }

  @override
  void removeObserver(BackendObserver observer) {}

  @override
  Future<Result<None, BackendError>> createUpdateProduct(String barcode,
      {VegStatus? vegetarianStatus, VegStatus? veganStatus}) async {
    await _delay();
    return Ok(None());
  }

  @override
  Future<bool> isLoggedIn() async {
    await _delay();
    return true;
  }

  @override
  Future<Result<UserParams, BackendError>> loginOrRegister(
      String googleIdToken) async {
    await _delay();
    return Ok(_userParams);
  }

  @override
  Future<Result<None, BackendError>> sendProductScan(String barcode) async {
    await _delay();
    return Ok(None());
  }

  @override
  Future<Result<None, BackendError>> sendReport(
      String barcode, String reportText) async {
    await _delay();
    return Ok(None());
  }

  @override
  Future<Result<bool, BackendError>> updateUserParams(UserParams userParams,
      {String? backendClientTokenOverride}) async {
    await _delay();
    _userParams = userParams;
    return Ok(true);
  }

  @override
  Future<Result<UserParams, BackendError>> userData() async {
    await _delay();
    return Ok(_userParams);
  }

  @override
  Future<Result<None, BackendError>> productPresenceVote(
      String barcode, String osmId, bool positive) async {
    await _delay();
    return Ok(None());
  }

  @override
  Future<Result<BackendProduct?, BackendError>> requestProduct(
      String barcode) async {
    await _delay();
    return Ok(_createBackendProduct(barcode));
  }

  BackendProduct _createBackendProduct(String barcode) {
    return BackendProduct((e) => e
      ..barcode = barcode
      ..veganStatus = VegStatus.unknown.name
      ..veganStatusSource = VegStatusSource.community.name
      ..vegetarianStatus = VegStatus.unknown.name
      ..vegetarianStatusSource = VegStatusSource.unknown.name);
  }

  @override
  Future<Result<List<BackendProductsAtShop>, BackendError>>
      requestProductsAtShops(Iterable<String> osmIds) async {
    await _delay();

    final result = <BackendProductsAtShop>[];
    for (final osmId in osmIds) {
      _createFakeShopIfNotExists(osmId: osmId);
      result.add(_fakeShops[osmId]!);
    }

    return Ok(result);
  }

  @override
  Future<Result<None, BackendError>> putProductToShop(
      String barcode, String osmId) async {
    await _delay();

    _createFakeShopIfNotExists(osmId: osmId);
    _fakeShops[osmId] = _fakeShops[osmId]!.rebuild((e) => e
      ..products.add(_createBackendProduct(barcode))
      ..productsLastSeenUtc[barcode] = _nowSecs());
    return Ok(None());
  }

  @override
  Future<Result<List<BackendShop>, BackendError>> requestShops(
      Iterable<String> osmIds) async {
    await _delay();

    final result = <BackendShop>[];
    for (final osmId in osmIds) {
      _createFakeShopIfNotExists(osmId: osmId);
      result.add(_fakeShops[osmId]!.toShop());
    }
    return Ok(result);
  }

  @override
  Future<Result<BackendShop, BackendError>> createShop(
      {required String name,
      required Point<double> coords,
      required String type}) async {
    return Ok(_createFakeShopIfNotExists(productsNumber: 0).toShop());
  }

  BackendProductsAtShop _createFakeShopIfNotExists(
      {String? osmId, int? productsNumber}) {
    if (_fakeShops.containsKey(osmId)) {
      return _fakeShops[osmId]!;
    }
    osmId ??= DateTime.now().millisecondsSinceEpoch.toString();
    if (randInt(0, 2) == 1) {
      productsNumber ??= 0;
    } else {
      productsNumber ??= randInt(1, 5);
    }
    final fakeProducts = <BackendProduct>[];
    for (var i = 0; i < productsNumber; ++i) {
      fakeProducts.add(_createBackendProduct(randInt(100, 200).toString()));
    }
    final lastSeen = <String, int>{};
    for (final product in fakeProducts) {
      lastSeen[product.barcode] = _nowSecs() - 60 * 60 * 24 * randInt(1, 10);
    }

    final productsAtShop = BackendProductsAtShop((e) => e
      ..osmId = osmId
      ..products.addAll(fakeProducts)
      ..productsLastSeenUtc.addAll(lastSeen));
    _fakeShops[osmId] = productsAtShop;
    return productsAtShop;
  }
}

extension _ProductsAtShopExt on BackendProductsAtShop {
  BackendShop toShop() {
    return BackendShop((e) => e
      ..osmId = osmId
      ..productsCount = products.length);
  }
}
