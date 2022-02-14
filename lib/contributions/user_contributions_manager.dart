import 'package:plante/base/base.dart';
import 'package:plante/base/cached_lazy_op.dart';
import 'package:plante/base/result.dart';
import 'package:plante/contributions/user_contribution.dart';
import 'package:plante/contributions/user_contribution_type.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/products/products_manager.dart';

// NOTE: this class is lazy - it doesn't request contributions unless
// is asked to. Because of this the class does not support observers.
class UserContributionsManager {
  static const SUPPORTED_CONTRIBUTIONS = {
    UserContributionType.UNKNOWN,
    UserContributionType.PRODUCT_EDITED,
    UserContributionType.PRODUCT_ADDED_TO_SHOP,
    UserContributionType.PRODUCT_REPORTED,
    UserContributionType.SHOP_CREATED,
    UserContributionType.LEGACY_PRODUCT_EDITED,
  };
  static const _REQUESTED_CONTRIBUTIONS_LIMIT = 50;

  final Backend _backend;
  final ProductsManager _productsManager;
  final ShopsManager _shopsManager;
  final UserReportsMaker _userReportsMaker;

  late final CachedLazyOp<List<UserContribution>, BackendError>
      _backendContributionsRequest;
  late List<UserContribution> _contributions;

  UserContributionsManager(this._backend, this._productsManager,
      this._shopsManager, this._userReportsMaker) {
    _backendContributionsRequest = CachedLazyOp(_requestContributions);
    final observer = _EverythingObserver(
      onProductEditedFn: _onProductEdited,
      onProductPutToShopsFn: _onProductPutToShops,
      onShopCreatedFn: _onShopCreated,
      onUserReportMadeFn: _onUserReportMade,
    );
    _productsManager.addObserver(observer);
    _shopsManager.addListener(observer);
    _userReportsMaker.addObserver(observer);
  }

  Future<Result<List<UserContribution>, BackendError>>
      _requestContributions() async {
    final result = await _backend.requestUserContributions(
        _REQUESTED_CONTRIBUTIONS_LIMIT, UserContributionType.values);
    if (result.isOk) {
      _contributions = <UserContribution>[];
      _contributions.addAll(result.unwrap());
    }
    return result;
  }

  Future<Result<List<UserContribution>, BackendError>>
      getContributions() async {
    final backendResult = await _backendContributionsRequest.result;
    if (backendResult.isErr) {
      return backendResult;
    }
    return Ok(_contributions);
  }

  void _onProductEdited(Product product) {
    if (!_backendContributionsRequest.done) {
      return;
    }
    _contributions.add(UserContribution.create(
        UserContributionType.PRODUCT_EDITED, DateTime.now(),
        barcode: product.barcode));
  }

  void _onUserReportMade(String barcode) {
    if (!_backendContributionsRequest.done) {
      return;
    }
    _contributions.add(UserContribution.create(
        UserContributionType.PRODUCT_REPORTED, DateTime.now(),
        barcode: barcode));
  }

  void _onShopCreated(Shop shop) {
    if (!_backendContributionsRequest.done) {
      return;
    }
    _contributions.add(UserContribution.create(
        UserContributionType.SHOP_CREATED, DateTime.now(),
        osmUID: shop.osmUID));
  }

  void _onProductPutToShops(Product product, List<Shop> shops) {
    if (!_backendContributionsRequest.done) {
      return;
    }
    for (final shop in shops) {
      _contributions.add(UserContribution.create(
          UserContributionType.PRODUCT_ADDED_TO_SHOP, DateTime.now(),
          barcode: product.barcode, osmUID: shop.osmUID));
    }
  }
}

class _EverythingObserver
    with
        ProductsManagerObserver,
        ShopsManagerListener,
        UserReportsMakerObserver {
  ArgCallback<Product> onProductEditedFn;
  ArgCallback<String> onUserReportMadeFn;
  ArgCallback<Shop> onShopCreatedFn;
  void Function(Product product, List<Shop> shops) onProductPutToShopsFn;

  _EverythingObserver(
      {required this.onProductEditedFn,
      required this.onUserReportMadeFn,
      required this.onShopCreatedFn,
      required this.onProductPutToShopsFn});

  @override
  void onProductEdited(Product product) {
    onProductEditedFn.call(product);
  }

  @override
  void onUserReportMade(String barcode) {
    onUserReportMadeFn.call(barcode);
  }

  @override
  void onShopCreated(Shop shop) {
    onShopCreatedFn.call(shop);
  }

  @override
  void onProductPutToShops(Product product, List<Shop> shops) {
    onProductPutToShopsFn.call(product, shops);
  }
}
