import 'package:http/http.dart' as http;
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_response.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';
import 'package:plante/outside/backend/product_presence_vote_result.dart';
import 'package:plante/outside/backend/requested_products_result.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

class FakeBackend implements Backend {
  final Settings _settings;

  FakeBackend(this._settings);

  UserParams _userParams = UserParams((e) => e
    ..backendId = DateTime.now().millisecondsSinceEpoch.toString()
    ..backendClientToken = 'token'
    ..name = 'Testing User for Fake Backend'
    ..userGroup = 2);
  final _fakeShops = <OsmUID, BackendProductsAtShop>{};

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
      {VegStatus? veganStatus, List<LangCode>? changedLangs}) async {
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
      {String? googleIdToken, String? appleAuthorizationCode}) async {
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
  Future<Result<MobileAppConfig, BackendError>> mobileAppConfig() async {
    await _delay();
    return Ok(MobileAppConfig((e) => e
      ..remoteUserParams.replace(_userParams)
      ..nominatimEnabled = true));
  }

  @override
  Future<Result<ProductPresenceVoteResult, BackendError>> productPresenceVote(
      String barcode, OsmUID osmUID, bool positive) async {
    await _delay();
    return Ok(ProductPresenceVoteResult(productDeleted: !positive));
  }

  @override
  Future<Result<RequestedProductsResult, BackendError>> requestProducts(
      List<String> barcodes, int page) async {
    await _delay();
    if (page > 0) {
      return Ok(RequestedProductsResult(const [], page, true));
    }
    final products = barcodes.map(_createBackendProduct).toList();
    return Ok(RequestedProductsResult(products, page, true));
  }

  BackendProduct _createBackendProduct(String barcode) {
    return BackendProduct((e) => e
      ..barcode = barcode
      ..veganStatus = VegStatus.unknown.name
      ..veganStatusSource = VegStatusSource.community.name);
  }

  @override
  Future<Result<List<BackendProductsAtShop>, BackendError>>
      requestProductsAtShops(Iterable<OsmUID> osmUIDs) async {
    await _delay();

    final result = <BackendProductsAtShop>[];
    for (final osmUID in osmUIDs) {
      _createFakeShopIfNotExists(osmUID: osmUID);
      result.add(_fakeShops[osmUID]!);
    }

    return Ok(result);
  }

  @override
  Future<Result<None, BackendError>> putProductToShop(
      String barcode, Shop shop) async {
    await _delay();

    final osmUID = shop.osmUID;
    _createFakeShopIfNotExists(osmUID: osmUID);
    _fakeShops[osmUID] = _fakeShops[osmUID]!.rebuild((e) => e
      ..products.add(_createBackendProduct(barcode))
      ..productsLastSeenUtc[barcode] = _nowSecs());
    return Ok(None());
  }

  @override
  Future<Result<List<BackendShop>, BackendError>> requestShopsByOsmUIDs(
      Iterable<OsmUID> osmUIDs) async {
    await _delay();

    final result = <BackendShop>[];
    for (final osmUID in osmUIDs) {
      _createFakeShopIfNotExists(osmUID: osmUID);
      result.add(_fakeShops[osmUID]!.toShop());
    }
    return Ok(result);
  }

  @override
  Future<Result<List<BackendShop>, BackendError>> requestShopsWithin(
      CoordsBounds bounds) async {
    return Ok(const []);
  }

  @override
  Future<Result<BackendShop, BackendError>> createShop(
      {required String name,
      required Coord coord,
      required String type}) async {
    return Ok(_createFakeShopIfNotExists(productsNumber: 0).toShop());
  }

  BackendProductsAtShop _createFakeShopIfNotExists(
      {OsmUID? osmUID, int? productsNumber}) {
    if (_fakeShops.containsKey(osmUID)) {
      return _fakeShops[osmUID]!;
    }
    osmUID ??=
        OsmUID.parse('1:${DateTime.now().millisecondsSinceEpoch.toString()}');
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
      ..osmUID = osmUID
      ..products.addAll(fakeProducts)
      ..productsLastSeenUtc.addAll(lastSeen));
    _fakeShops[osmUID] = productsAtShop;
    return productsAtShop;
  }

  @override
  Future<BackendResponse> customGet(String path,
      [Map<String, dynamic>? queryParams, Map<String, String>? headers]) {
    throw UnimplementedError('Not supposed to be used');
  }

  @override
  Future<R> customRequest<R extends http.BaseRequest>(
      String path, ArgResCallback<Uri, R> createRequest,
      {Map<String, dynamic>? queryParams, Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}

extension _ProductsAtShopExt on BackendProductsAtShop {
  BackendShop toShop() {
    return BackendShop((e) => e
      ..osmUID = osmUID
      ..productsCount = products.length);
  }
}
