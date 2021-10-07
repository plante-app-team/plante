import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/outside/products/products_obtainer.dart';

class FakeProductsObtainer implements ProductsObtainer {
  final _knownProducts = <String, Product>{};
  ArgResCallback<String, Product?>? unknownProductsGenerator;
  var inflatesCount = 0;

  FakeProductsObtainer(
      {List<Product>? knownProducts, this.unknownProductsGenerator}) {
    if (knownProducts != null) {
      _knownProducts.addAll(
          {for (final product in knownProducts) product.barcode: product});
    }
  }

  void addKnownProducts(Iterable<Product> products) {
    products.forEach(addKnownProduct);
  }

  void addKnownProduct(Product product) {
    _knownProducts[product.barcode] = product;
  }

  @override
  Future<Result<Product?, ProductsManagerError>> getProduct(
      String barcode) async {
    return Ok(_getProductNow(barcode));
  }

  Product? _getProductNow(String barcode) {
    final result = _knownProducts[barcode];
    if (result != null) {
      return result;
    }
    return unknownProductsGenerator?.call(barcode);
  }

  @override
  Future<Result<List<Product>, ProductsManagerError>> getProducts(
      List<String> barcodes) async {
    final products = <Product>[];
    for (final barcode in barcodes) {
      final product = _getProductNow(barcode);
      if (product != null) {
        products.add(product);
      }
    }
    return Ok(products);
  }

  @override
  Future<Result<Product?, ProductsManagerError>> inflate(
      BackendProduct backendProduct) async {
    inflatesCount += 1;
    return await getProduct(backendProduct.barcode);
  }

  @override
  Future<Result<List<Product>, ProductsManagerError>> inflateProducts(
      List<BackendProduct> backendProducts) async {
    inflatesCount += backendProducts.length;
    return await getProducts(backendProducts.map((e) => e.barcode).toList());
  }
}
