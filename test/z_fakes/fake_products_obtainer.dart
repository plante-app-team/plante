import 'dart:async';
import 'dart:ui';

import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_obtainer.dart';

class FakeProductsObtainer implements ProductsObtainer {
  final _knownProducts = <String, Product>{};
  final _resumeCallbacks = <VoidCallback>[];
  var _paused = false;

  /// A function which generates products for testing purposes
  ArgResCallback<String, Result<Product?, ProductsObtainerError>>?
      unknownProductsGenerator;

  var inflatesBackendProductsCount = 0;

  /// Same as [unknownProductsGenerator], but without [Result] logic
  set unknownProductsGeneratorSimple(ArgResCallback<String, Product?>? fn) {
    if (fn == null) {
      unknownProductsGenerator = null;
    } else {
      unknownProductsGenerator = (String barcode) => Ok(fn.call(barcode));
    }
  }

  /// Same as [unknownProductsGenerator], but without [Result] logic
  ArgResCallback<String, Product?>? get unknownProductsGeneratorSimple {
    if (unknownProductsGenerator == null) {
      return null;
    }
    return (String barcode) => unknownProductsGenerator!.call(barcode).unwrap();
  }

  FakeProductsObtainer(
      {List<Product>? knownProducts, this.unknownProductsGenerator}) {
    if (knownProducts != null) {
      _knownProducts.addAll(
          {for (final product in knownProducts) product.barcode: product});
    }
  }

  /// Makes all returned futures to not be resolved yet
  void pauseProductsRetrieval() {
    _paused = true;
  }

  /// Resolves all futures returned in the past
  void resumeProductsRetrieval() {
    _paused = false;
    final copy = _resumeCallbacks.toList();
    _resumeCallbacks.clear();
    copy.forEach((e) => e.call());
  }

  void addKnownProducts(Iterable<Product> products) {
    products.forEach(addKnownProduct);
  }

  void addKnownProduct(Product product) {
    _knownProducts[product.barcode] = product;
  }

  void clearKnownProducts() {
    _knownProducts.clear();
  }

  @override
  Future<Result<Product?, ProductsObtainerError>> getProduct(
      String barcode) async {
    return _turnIntoFuture(_getProductNow(barcode));
  }

  Future<T> _turnIntoFuture<T>(T value) {
    final completer = Completer<T>();
    final complete = () {
      completer.complete(value);
    };
    if (_paused) {
      _resumeCallbacks.add(complete);
    } else {
      complete.call();
    }
    return completer.future;
  }

  Result<Product?, ProductsObtainerError> _getProductNow(String barcode) {
    final result = _knownProducts[barcode];
    if (result != null) {
      return Ok(result);
    }
    if (unknownProductsGenerator != null) {
      return unknownProductsGenerator!.call(barcode);
    }
    return Ok(null);
  }

  @override
  Future<Result<List<Product>, ProductsObtainerError>> getProducts(
      List<String> barcodes) async {
    final products = <Product>[];
    for (final barcode in barcodes) {
      final productRes = _getProductNow(barcode);
      if (productRes.isErr) {
        return Err(productRes.unwrapErr());
      }
      final product = productRes.unwrap();
      if (product != null) {
        products.add(product);
      }
    }
    return _turnIntoFuture(Ok(products));
  }

  @override
  Future<Result<Product?, ProductsObtainerError>> inflate(
      BackendProduct backendProduct) async {
    inflatesBackendProductsCount += 1;
    return _turnIntoFuture(_getProductNow(backendProduct.barcode));
  }

  @override
  Future<Result<List<Product>, ProductsObtainerError>> inflateProducts(
      List<BackendProduct> backendProducts) async {
    inflatesBackendProductsCount += backendProducts.length;
    return await getProducts(backendProducts.map((e) => e.barcode).toList());
  }

  @override
  Future<Result<List<Product>, ProductsObtainerError>> inflateOffProducts(
      List<off.Product> offProducts) async {
    return await getProducts(offProducts.map((e) => e.barcode!).toList());
  }
}
