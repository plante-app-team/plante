import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/requested_products_result.dart';

const REQUEST_PRODUCTS_CMD = 'products_data';

extension BackendExt on Backend {
  Future<Result<RequestedProductsResult, BackendError>> requestProducts(
          List<String> barcodes, int page) =>
      executeCmd(_RequestProductsCmd(barcodes, page));
}

class _RequestProductsCmd extends BackendCmd<RequestedProductsResult> {
  final List<String> barcodes;
  final int page;
  _RequestProductsCmd(this.barcodes, this.page);

  @override
  Future<Result<RequestedProductsResult, BackendError>> execute() async {
    final jsonRes = await backendGetJson(
        '$REQUEST_PRODUCTS_CMD/', {'barcodes': barcodes, 'page': '$page'});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    if (!json.containsKey('products') || !json.containsKey('last_page')) {
      Log.w('Invalid product_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final result = <BackendProduct>[];
    final productsJson = json['products'] as List<dynamic>;
    for (final productJson in productsJson) {
      final product =
          BackendProduct.fromJson(productJson as Map<String, dynamic>);
      if (product == null) {
        Log.w('Product could not pe parsed: $productJson');
        continue;
      }
      result.add(product);
    }
    return Ok(RequestedProductsResult(result, page, json['last_page'] as bool));
  }
}
