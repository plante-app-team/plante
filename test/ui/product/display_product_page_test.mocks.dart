// Mocks generated by Mockito 5.0.3 from annotations
// in plante/test/ui/product/display_product_page_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i5;
import 'dart:io' as _i24;
import 'dart:math' as _i3;

import 'package:flutter/src/services/message_codec.dart' as _i25;
import 'package:flutter/src/widgets/framework.dart' as _i23;
import 'package:mockito/mockito.dart' as _i1;
import 'package:plante/base/base.dart' as _i16;
import 'package:plante/base/permissions_manager.dart' as _i26;
import 'package:plante/base/result.dart' as _i2;
import 'package:plante/location/location_controller.dart' as _i15;
import 'package:plante/model/product.dart' as _i6;
import 'package:plante/model/shop.dart' as _i19;
import 'package:plante/model/shop_product_range.dart' as _i20;
import 'package:plante/model/shop_type.dart' as _i21;
import 'package:plante/model/user_params.dart' as _i10;
import 'package:plante/model/veg_status.dart' as _i12;
import 'package:plante/outside/backend/backend.dart' as _i9;
import 'package:plante/outside/backend/backend_error.dart' as _i11;
import 'package:plante/outside/backend/backend_product.dart' as _i8;
import 'package:plante/outside/backend/backend_products_at_shop.dart' as _i13;
import 'package:plante/outside/backend/backend_shop.dart' as _i14;
import 'package:plante/outside/map/shops_manager.dart' as _i17;
import 'package:plante/outside/map/shops_manager_types.dart' as _i18;
import 'package:plante/outside/products/products_manager.dart' as _i4;
import 'package:plante/outside/products/products_manager_error.dart' as _i7;
import 'package:plante/ui/photos_taker.dart' as _i22;

// ignore_for_file: comment_references
// ignore_for_file: unnecessary_parenthesis

class _FakeResult<OK, ERR> extends _i1.Fake implements _i2.Result<OK, ERR> {}

class _FakePoint<T extends num> extends _i1.Fake implements _i3.Point<T> {}

class _FakeUri extends _i1.Fake implements Uri {}

/// A class which mocks [ProductsManager].
///
/// See the documentation for Mockito's code generation for more information.
class MockProductsManager extends _i1.Mock implements _i4.ProductsManager {
  MockProductsManager() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<_i2.Result<_i6.Product?, _i7.ProductsManagerError>> getProduct(
          String? barcodeRaw,
          [String? langCode]) =>
      (super.noSuchMethod(
              Invocation.method(#getProduct, [barcodeRaw, langCode]),
              returnValue: Future.value(
                  _FakeResult<_i6.Product?, _i7.ProductsManagerError>()))
          as _i5.Future<_i2.Result<_i6.Product?, _i7.ProductsManagerError>>);
  @override
  _i5.Future<_i2.Result<_i6.Product?, _i7.ProductsManagerError>> inflate(
          _i8.BackendProduct? backendProduct,
          [String? langCode]) =>
      (super.noSuchMethod(
              Invocation.method(#inflate, [backendProduct, langCode]),
              returnValue: Future.value(
                  _FakeResult<_i6.Product?, _i7.ProductsManagerError>()))
          as _i5.Future<_i2.Result<_i6.Product?, _i7.ProductsManagerError>>);
  @override
  _i5.Future<_i2.Result<_i6.Product, _i7.ProductsManagerError>>
      createUpdateProduct(_i6.Product? product, [String? langCode]) => (super
              .noSuchMethod(
                  Invocation.method(#createUpdateProduct, [product, langCode]),
                  returnValue: Future.value(
                      _FakeResult<_i6.Product, _i7.ProductsManagerError>()))
          as _i5.Future<_i2.Result<_i6.Product, _i7.ProductsManagerError>>);
  @override
  _i5.Future<_i2.Result<_i4.ProductWithOCRIngredients, _i7.ProductsManagerError>>
      updateProductAndExtractIngredients(_i6.Product? product,
              [String? langCode]) =>
          (super.noSuchMethod(
              Invocation.method(
                  #updateProductAndExtractIngredients, [product, langCode]),
              returnValue: Future.value(
                  _FakeResult<_i4.ProductWithOCRIngredients, _i7.ProductsManagerError>())) as _i5
              .Future<_i2.Result<_i4.ProductWithOCRIngredients, _i7.ProductsManagerError>>);
}

/// A class which mocks [Backend].
///
/// See the documentation for Mockito's code generation for more information.
class MockBackend extends _i1.Mock implements _i9.Backend {
  MockBackend() {
    _i1.throwOnMissingStub(this);
  }

  @override
  void addObserver(_i9.BackendObserver? observer) =>
      super.noSuchMethod(Invocation.method(#addObserver, [observer]),
          returnValueForMissingStub: null);
  @override
  void removeObserver(_i9.BackendObserver? observer) =>
      super.noSuchMethod(Invocation.method(#removeObserver, [observer]),
          returnValueForMissingStub: null);
  @override
  _i5.Future<bool> isLoggedIn() =>
      (super.noSuchMethod(Invocation.method(#isLoggedIn, []),
          returnValue: Future.value(false)) as _i5.Future<bool>);
  @override
  _i5.Future<_i2.Result<_i10.UserParams, _i11.BackendError>> loginOrRegister(
          String? googleIdToken) =>
      (super.noSuchMethod(Invocation.method(#loginOrRegister, [googleIdToken]),
              returnValue: Future.value(
                  _FakeResult<_i10.UserParams, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i10.UserParams, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<bool, _i11.BackendError>> updateUserParams(
          _i10.UserParams? userParams,
          {String? backendClientTokenOverride}) =>
      (super.noSuchMethod(
              Invocation.method(#updateUserParams, [userParams],
                  {#backendClientTokenOverride: backendClientTokenOverride}),
              returnValue: Future.value(_FakeResult<bool, _i11.BackendError>()))
          as _i5.Future<_i2.Result<bool, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i8.BackendProduct?, _i11.BackendError>> requestProduct(
          String? barcode) =>
      (super.noSuchMethod(Invocation.method(#requestProduct, [barcode]),
              returnValue: Future.value(
                  _FakeResult<_i8.BackendProduct?, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i8.BackendProduct?, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i2.None, _i11.BackendError>> createUpdateProduct(
          String? barcode,
          {_i12.VegStatus? vegetarianStatus,
          _i12.VegStatus? veganStatus}) =>
      (super.noSuchMethod(
              Invocation.method(#createUpdateProduct, [
                barcode
              ], {
                #vegetarianStatus: vegetarianStatus,
                #veganStatus: veganStatus
              }),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i2.None, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i2.None, _i11.BackendError>> sendReport(
          String? barcode, String? reportText) =>
      (super.noSuchMethod(Invocation.method(#sendReport, [barcode, reportText]),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i2.None, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i2.None, _i11.BackendError>> sendProductScan(
          String? barcode) =>
      (super.noSuchMethod(Invocation.method(#sendProductScan, [barcode]),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i2.None, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i10.UserParams, _i11.BackendError>> userData() =>
      (super.noSuchMethod(Invocation.method(#userData, []),
              returnValue: Future.value(
                  _FakeResult<_i10.UserParams, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i10.UserParams, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<List<_i13.BackendProductsAtShop>, _i11.BackendError>>
      requestProductsAtShops(Iterable<String>? osmIds) => (super.noSuchMethod(
          Invocation.method(#requestProductsAtShops, [osmIds]),
          returnValue: Future.value(_FakeResult<
              List<_i13.BackendProductsAtShop>, _i11.BackendError>())) as _i5
          .Future<_i2.Result<List<_i13.BackendProductsAtShop>, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<List<_i14.BackendShop>, _i11.BackendError>>
      requestShops(Iterable<String>? osmIds) => (super.noSuchMethod(
              Invocation.method(#requestShops, [osmIds]),
              returnValue: Future.value(
                  _FakeResult<List<_i14.BackendShop>, _i11.BackendError>()))
          as _i5.Future<_i2.Result<List<_i14.BackendShop>, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i2.None, _i11.BackendError>> productPresenceVote(
          String? barcode, String? osmId, bool? positive) =>
      (super.noSuchMethod(
          Invocation.method(#productPresenceVote, [barcode, osmId, positive]),
          returnValue:
              Future.value(_FakeResult<_i2.None, _i11.BackendError>())) as _i5
          .Future<_i2.Result<_i2.None, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i2.None, _i11.BackendError>> putProductToShop(
          String? barcode, String? osmId) =>
      (super.noSuchMethod(
              Invocation.method(#putProductToShop, [barcode, osmId]),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i2.None, _i11.BackendError>>);
  @override
  _i5.Future<_i2.Result<_i14.BackendShop, _i11.BackendError>> createShop(
          {String? name, _i3.Point<double>? coords, String? type}) =>
      (super.noSuchMethod(
              Invocation.method(
                  #createShop, [], {#name: name, #coords: coords, #type: type}),
              returnValue: Future.value(
                  _FakeResult<_i14.BackendShop, _i11.BackendError>()))
          as _i5.Future<_i2.Result<_i14.BackendShop, _i11.BackendError>>);
}

/// A class which mocks [LocationController].
///
/// See the documentation for Mockito's code generation for more information.
class MockLocationController extends _i1.Mock
    implements _i15.LocationController {
  MockLocationController() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<_i3.Point<double>?> lastKnownPosition() =>
      (super.noSuchMethod(Invocation.method(#lastKnownPosition, []),
              returnValue: Future.value(_FakePoint<double>()))
          as _i5.Future<_i3.Point<double>?>);
  @override
  _i5.Future<_i3.Point<double>?> currentPosition() =>
      (super.noSuchMethod(Invocation.method(#currentPosition, []),
              returnValue: Future.value(_FakePoint<double>()))
          as _i5.Future<_i3.Point<double>?>);
  @override
  void callWhenLastPositionKnown(
          _i16.ArgCallback<_i3.Point<double>>? callback) =>
      super.noSuchMethod(
          Invocation.method(#callWhenLastPositionKnown, [callback]),
          returnValueForMissingStub: null);
}

/// A class which mocks [ShopsManager].
///
/// See the documentation for Mockito's code generation for more information.
class MockShopsManager extends _i1.Mock implements _i17.ShopsManager {
  MockShopsManager() {
    _i1.throwOnMissingStub(this);
  }

  @override
  int get loadedAreasCount =>
      (super.noSuchMethod(Invocation.getter(#loadedAreasCount), returnValue: 0)
          as int);
  @override
  void addListener(_i18.ShopsManagerListener? listener) =>
      super.noSuchMethod(Invocation.method(#addListener, [listener]),
          returnValueForMissingStub: null);
  @override
  void removeListener(_i18.ShopsManagerListener? listener) =>
      super.noSuchMethod(Invocation.method(#removeListener, [listener]),
          returnValueForMissingStub: null);
  @override
  _i5.Future<
      _i2.Result<Map<String, _i19.Shop>, _i18.ShopsManagerError>> fetchShops(
          _i3.Point<double>? northeast, _i3.Point<double>? southwest) =>
      (super.noSuchMethod(
          Invocation.method(#fetchShops, [northeast, southwest]),
          returnValue: Future.value(
              _FakeResult<Map<String, _i19.Shop>, _i18.ShopsManagerError>())) as _i5
          .Future<_i2.Result<Map<String, _i19.Shop>, _i18.ShopsManagerError>>);
  @override
  _i5.Future<_i2.Result<_i20.ShopProductRange, _i18.ShopsManagerError>>
      fetchShopProductRange(_i19.Shop? shop, {bool? noCache = false}) => (super
              .noSuchMethod(
                  Invocation.method(
                      #fetchShopProductRange, [shop], {#noCache: noCache}),
                  returnValue: Future.value(
                      _FakeResult<_i20.ShopProductRange, _i18.ShopsManagerError>()))
          as _i5
              .Future<_i2.Result<_i20.ShopProductRange, _i18.ShopsManagerError>>);
  @override
  _i5.Future<_i2.Result<_i2.None, _i18.ShopsManagerError>> putProductToShops(
          _i6.Product? product, List<_i19.Shop>? shops) =>
      (super.noSuchMethod(
              Invocation.method(#putProductToShops, [product, shops]),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i18.ShopsManagerError>()))
          as _i5.Future<_i2.Result<_i2.None, _i18.ShopsManagerError>>);
  @override
  _i5.Future<_i2.Result<_i19.Shop, _i18.ShopsManagerError>> createShop(
          {String? name, _i3.Point<double>? coords, _i21.ShopType? type}) =>
      (super.noSuchMethod(
              Invocation.method(
                  #createShop, [], {#name: name, #coords: coords, #type: type}),
              returnValue: Future.value(
                  _FakeResult<_i19.Shop, _i18.ShopsManagerError>()))
          as _i5.Future<_i2.Result<_i19.Shop, _i18.ShopsManagerError>>);
}

/// A class which mocks [PhotosTaker].
///
/// See the documentation for Mockito's code generation for more information.
class MockPhotosTaker extends _i1.Mock implements _i22.PhotosTaker {
  MockPhotosTaker() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<Uri?> takeAndCropPhoto(
          _i23.BuildContext? context, _i24.Directory? outFolder) =>
      (super.noSuchMethod(
          Invocation.method(#takeAndCropPhoto, [context, outFolder]),
          returnValue: Future.value(_FakeUri())) as _i5.Future<Uri?>);
  @override
  _i5.Future<Uri?> cropPhoto(String? photoPath, _i23.BuildContext? context,
          _i24.Directory? outFolder) =>
      (super.noSuchMethod(
          Invocation.method(#cropPhoto, [photoPath, context, outFolder]),
          returnValue: Future.value(_FakeUri())) as _i5.Future<Uri?>);
  @override
  _i5.Future<_i2.Result<Uri, _i25.PlatformException>?> retrieveLostPhoto() =>
      (super.noSuchMethod(Invocation.method(#retrieveLostPhoto, []),
              returnValue:
                  Future.value(_FakeResult<Uri, _i25.PlatformException>()))
          as _i5.Future<_i2.Result<Uri, _i25.PlatformException>?>);
}

/// A class which mocks [PermissionsManager].
///
/// See the documentation for Mockito's code generation for more information.
class MockPermissionsManager extends _i1.Mock
    implements _i26.PermissionsManager {
  MockPermissionsManager() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<_i26.PermissionState> status(_i26.PermissionKind? permission) =>
      (super.noSuchMethod(Invocation.method(#status, [permission]),
              returnValue: Future.value(_i26.PermissionState.granted))
          as _i5.Future<_i26.PermissionState>);
  @override
  _i5.Future<_i26.PermissionState> request(_i26.PermissionKind? permission) =>
      (super.noSuchMethod(Invocation.method(#request, [permission]),
              returnValue: Future.value(_i26.PermissionState.granted))
          as _i5.Future<_i26.PermissionState>);
  @override
  _i5.Future<bool> openAppSettings() =>
      (super.noSuchMethod(Invocation.method(#openAppSettings, []),
          returnValue: Future.value(false)) as _i5.Future<bool>);
}
