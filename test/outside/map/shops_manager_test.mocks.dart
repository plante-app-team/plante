// Mocks generated by Mockito 5.0.3 from annotations
// in plante/test/outside/map/shops_manager_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i4;
import 'dart:math' as _i6;

import 'package:mockito/mockito.dart' as _i1;
import 'package:plante/base/result.dart' as _i2;
import 'package:plante/model/user_params.dart' as _i8;
import 'package:plante/model/veg_status.dart' as _i11;
import 'package:plante/outside/backend/backend.dart' as _i7;
import 'package:plante/outside/backend/backend_error.dart' as _i9;
import 'package:plante/outside/backend/backend_product.dart' as _i10;
import 'package:plante/outside/backend/backend_products_at_shop.dart' as _i12;
import 'package:plante/outside/map/open_street_map.dart' as _i3;
import 'package:plante/outside/map/osm_shop.dart' as _i5;

// ignore_for_file: comment_references
// ignore_for_file: unnecessary_parenthesis

class _FakeResult<OK, ERR> extends _i1.Fake implements _i2.Result<OK, ERR> {}

/// A class which mocks [OpenStreetMap].
///
/// See the documentation for Mockito's code generation for more information.
class MockOpenStreetMap extends _i1.Mock implements _i3.OpenStreetMap {
  MockOpenStreetMap() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.Result<List<_i5.OsmShop>, _i3.OpenStreetMapError>> fetchShops(
          _i6.Point<double>? northeast, _i6.Point<double>? southwest) =>
      (super.noSuchMethod(
              Invocation.method(#fetchShops, [northeast, southwest]),
              returnValue: Future.value(
                  _FakeResult<List<_i5.OsmShop>, _i3.OpenStreetMapError>()))
          as _i4.Future<_i2.Result<List<_i5.OsmShop>, _i3.OpenStreetMapError>>);
}

/// A class which mocks [Backend].
///
/// See the documentation for Mockito's code generation for more information.
class MockBackend extends _i1.Mock implements _i7.Backend {
  MockBackend() {
    _i1.throwOnMissingStub(this);
  }

  @override
  void addObserver(_i7.BackendObserver? observer) =>
      super.noSuchMethod(Invocation.method(#addObserver, [observer]),
          returnValueForMissingStub: null);
  @override
  void removeObserver(_i7.BackendObserver? observer) =>
      super.noSuchMethod(Invocation.method(#removeObserver, [observer]),
          returnValueForMissingStub: null);
  @override
  _i4.Future<bool> isLoggedIn() =>
      (super.noSuchMethod(Invocation.method(#isLoggedIn, []),
          returnValue: Future.value(false)) as _i4.Future<bool>);
  @override
  _i4.Future<_i2.Result<_i8.UserParams, _i9.BackendError>> loginOrRegister(
          String? googleIdToken) =>
      (super.noSuchMethod(Invocation.method(#loginOrRegister, [googleIdToken]),
              returnValue:
                  Future.value(_FakeResult<_i8.UserParams, _i9.BackendError>()))
          as _i4.Future<_i2.Result<_i8.UserParams, _i9.BackendError>>);
  @override
  _i4.Future<_i2.Result<bool, _i9.BackendError>> updateUserParams(
          _i8.UserParams? userParams,
          {String? backendClientTokenOverride}) =>
      (super.noSuchMethod(
              Invocation.method(#updateUserParams, [userParams],
                  {#backendClientTokenOverride: backendClientTokenOverride}),
              returnValue: Future.value(_FakeResult<bool, _i9.BackendError>()))
          as _i4.Future<_i2.Result<bool, _i9.BackendError>>);
  @override
  _i4.Future<_i2.Result<_i10.BackendProduct?, _i9.BackendError>> requestProduct(
          String? barcode) =>
      (super.noSuchMethod(Invocation.method(#requestProduct, [barcode]),
              returnValue: Future.value(
                  _FakeResult<_i10.BackendProduct?, _i9.BackendError>()))
          as _i4.Future<_i2.Result<_i10.BackendProduct?, _i9.BackendError>>);
  @override
  _i4.Future<_i2.Result<_i2.None, _i9.BackendError>> createUpdateProduct(
          String? barcode,
          {_i11.VegStatus? vegetarianStatus,
          _i11.VegStatus? veganStatus}) =>
      (super.noSuchMethod(
              Invocation.method(#createUpdateProduct, [
                barcode
              ], {
                #vegetarianStatus: vegetarianStatus,
                #veganStatus: veganStatus
              }),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i9.BackendError>()))
          as _i4.Future<_i2.Result<_i2.None, _i9.BackendError>>);
  @override
  _i4.Future<_i2.Result<_i2.None, _i9.BackendError>> sendReport(
          String? barcode, String? reportText) =>
      (super.noSuchMethod(Invocation.method(#sendReport, [barcode, reportText]),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i9.BackendError>()))
          as _i4.Future<_i2.Result<_i2.None, _i9.BackendError>>);
  @override
  _i4.Future<_i2.Result<_i2.None, _i9.BackendError>> sendProductScan(
          String? barcode) =>
      (super.noSuchMethod(Invocation.method(#sendProductScan, [barcode]),
              returnValue:
                  Future.value(_FakeResult<_i2.None, _i9.BackendError>()))
          as _i4.Future<_i2.Result<_i2.None, _i9.BackendError>>);
  @override
  _i4.Future<_i2.Result<_i8.UserParams, _i9.BackendError>> userData() =>
      (super.noSuchMethod(Invocation.method(#userData, []),
              returnValue:
                  Future.value(_FakeResult<_i8.UserParams, _i9.BackendError>()))
          as _i4.Future<_i2.Result<_i8.UserParams, _i9.BackendError>>);
  @override
  _i4.Future<_i2.Result<List<_i12.BackendProductsAtShop>, _i9.BackendError>>
      requestProductsAtShops(Iterable<String>? osmIds) => (super.noSuchMethod(
          Invocation.method(#requestProductsAtShops, [osmIds]),
          returnValue: Future.value(_FakeResult<
              List<_i12.BackendProductsAtShop>, _i9.BackendError>())) as _i4
          .Future<_i2.Result<List<_i12.BackendProductsAtShop>, _i9.BackendError>>);
}
