import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/barcode_utils.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/scan/barcode_scan_page_content_state.dart';

enum BarcodeScanPageSearchResult { OK, ERROR_NETWORK, ERROR_OTHER }

class BarcodeScanPageModel
    with WidgetsBindingObserver
    implements UserLangsManagerObserver {
  final VoidCallback _onStateChangeCallback;
  final ResCallback<BarcodeScanPage> _widgetCallback;
  final ResCallback<BuildContext> _contextCallback;
  final ProductsObtainer _productsObtainer;
  final ShopsManager _shopsManager;
  final PermissionsManager _permissionsManager;
  final UserParamsController _userParamsController;
  final UserLangsManager _userLangsManager;
  final ViewedProductsStorage _viewedProductsStorage;
  final Analytics _analytics;

  String? _barcode;
  bool _searching = false;
  Product? _foundProduct;
  PermissionState? _cameraPermission;
  String _manualBarcode = '';
  bool _manualBarcodeInputShown = false;
  List<LangCode>? _userLangs;

  BarcodeScanPage get _widget => _widgetCallback.call();
  BuildContext get _context => _contextCallback.call();

  String? get barcode => _barcode;
  bool get searching => _searching;
  bool get cameraAvailable => _cameraPermission == PermissionState.granted;
  bool get manualBarcodeInputShown => _manualBarcodeInputShown;

  set manualBarcodeInputShown(bool value) {
    _manualBarcodeInputShown = value;
    _widgetCallback.call();
  }

  BarcodeScanPageModel(
      this._onStateChangeCallback,
      this._widgetCallback,
      this._contextCallback,
      this._productsObtainer,
      this._shopsManager,
      this._permissionsManager,
      this._userParamsController,
      this._userLangsManager,
      this._viewedProductsStorage,
      this._analytics) {
    _updateCameraPermission();
    WidgetsBinding.instance!.addObserver(this);
    _userLangsManager.addObserver(this);
    _userLangsManager.getUserLangs().then(onUserLangsChange);
  }

  @override
  void onUserLangsChange(UserLangs userLangs) {
    _userLangs = userLangs.langs.toList();
    _onStateChangeCallback.call();
  }

  void _updateCameraPermission() async {
    final permission = await _permissionsManager.status(PermissionKind.CAMERA);
    if (permission == PermissionState.denied &&
        _cameraPermission == PermissionState.permanentlyDenied) {
      // That's a trick the OS plays on us!
      // In the reality camera permission is still permanently denied.
      return;
    }
    _cameraPermission = permission;
    _onStateChangeCallback.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateCameraPermission();
    }
  }

  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    _userLangsManager.removeObserver(this);
  }

  void _onProductExternalUpdate(Product updatedProduct) {
    _foundProduct = updatedProduct;
    _onStateChangeCallback.call();
  }

  void _onFoundProductCanceled() {
    _foundProduct = null;
    _barcode = null;
    _onStateChangeCallback.call();
  }

  BarcodeScanPageContentState get contentState {
    if (_cameraPermission != null &&
        _cameraPermission != PermissionState.granted &&
        !_manualBarcodeInputShown) {
      if (_cameraPermission == PermissionState.denied) {
        final requestPermission = () async {
          _cameraPermission =
              await _permissionsManager.request(PermissionKind.CAMERA);
          _onStateChangeCallback.call();
        };
        return BarcodeScanPageContentState.noPermission(requestPermission);
      } else {
        return BarcodeScanPageContentState.cannotAskPermission(
            _permissionsManager.openAppSettings);
      }
    } else if (_barcode == null) {
      return BarcodeScanPageContentState.nothingScanned();
    } else if (_searching && _barcode != null) {
      return BarcodeScanPageContentState.searchingProduct(_barcode!);
    } else if (_foundProduct != null &&
        ProductPageWrapper.isProductFilledEnoughForDisplay(_foundProduct!)) {
      if (_widget.addProductToShop != null) {
        return BarcodeScanPageContentState.addProductToShop(
            _foundProduct!,
            _widget.addProductToShop!,
            _addProductToShop,
            _onFoundProductCanceled);
      } else if (_userLangs == null) {
        return BarcodeScanPageContentState.searchingProduct(_barcode!);
      } else if (ProductPageWrapper.isProductFilledEnoughForDisplayInLangs(
          _foundProduct!, _userLangs!)) {
        return BarcodeScanPageContentState.productFound(
            _foundProduct!,
            _userParamsController.cachedUserParams!,
            _tryOpenProductPage,
            _onFoundProductCanceled);
      } else {
        return BarcodeScanPageContentState.productFoundInOtherLangs(
            _foundProduct!,
            _userParamsController.cachedUserParams!,
            _tryOpenProductPage,
            _openProductPageToAddInfo,
            _onFoundProductCanceled);
      }
    } else {
      final Product product;
      if (_foundProduct != null) {
        product = _foundProduct!;
      } else {
        product = Product((v) => v.barcode = _barcode);
      }
      return BarcodeScanPageContentState.productNotFound(
          product, _widget.addProductToShop, () {
        _tryOpenProductPageFor(product);
      }, _onFoundProductCanceled);
    }
  }

  void _tryOpenProductPage() {
    _tryOpenProductPageFor(_foundProduct!);
  }

  void _tryOpenProductPageFor(Product product) {
    if (_widget.addProductToShop != null) {
      Navigator.of(_context).pop();
    }
    ProductPageWrapper.show(_context, product,
        shopToAddTo: _widget.addProductToShop,
        productUpdatedCallback: _onProductExternalUpdate);
  }

  void _openProductPageToAddInfo() {
    _analytics.sendEvent('barcode_scan_page_clicked_add_info_in_lang');
    Navigator.push(
      _context,
      MaterialPageRoute(
          builder: (context) => InitProductPage(_foundProduct!,
              key: const Key('init_product_page'),
              productUpdatedCallback: _onProductExternalUpdate)),
    );
  }

  Future<BarcodeScanPageSearchResult> searchProduct(String barcode) async {
    Log.i('BarcodeScanPageModel.searchProduct start: $barcode');
    _barcode = barcode;
    _searching = true;

    Result<Product?, ProductsObtainerError> foundProductResult;
    Product? foundProduct;
    try {
      _onStateChangeCallback.call();
      foundProductResult = await _productsObtainer.getProduct(barcode);
      foundProduct = foundProductResult.maybeOk();
      _barcode = foundProductResult.isOk ? barcode : null;
      _foundProduct = foundProduct;
      Log.i(
          'BarcodeScanPageModel.searchProduct success, product: $foundProduct');
    } catch (e) {
      Log.w('BarcodeScanPageModel.searchProduct failure', ex: e);
      rethrow;
    } finally {
      _searching = false;
      _onStateChangeCallback.call();
    }

    if (foundProduct != null && _userLangs != null) {
      if (ProductPageWrapper.isProductFilledEnoughForDisplayInLangs(
          foundProduct, _userLangs!)) {
        _analytics.sendEvent('scanned_product_in_user_lang');
      } else {
        _analytics.sendEvent('scanned_product_in_foreign_lang');
      }
    }

    if (foundProduct != null &&
        ProductPageWrapper.isProductFilledEnoughForDisplay(foundProduct)) {
      await _viewedProductsStorage.addProduct(foundProduct);
    }

    if (foundProductResult.isErr) {
      if (foundProductResult.unwrapErr() == ProductsObtainerError.NETWORK) {
        return BarcodeScanPageSearchResult.ERROR_NETWORK;
      } else {
        return BarcodeScanPageSearchResult.ERROR_OTHER;
      }
    } else {
      return BarcodeScanPageSearchResult.OK;
    }
  }

  void manualBarcodeChanged(String value) {
    _manualBarcode = value;
    _onStateChangeCallback.call();
  }

  bool isManualBarcodeValid() {
    return isBarcodeValid(_manualBarcode);
  }

  Future<Result<None, ShopsManagerError>> _addProductToShop() async {
    final product = _foundProduct!;
    final shop = _widget.addProductToShop!;
    return _shopsManager.putProductToShops(
        product, [shop], ProductAtShopSource.MANUAL);
  }
}
