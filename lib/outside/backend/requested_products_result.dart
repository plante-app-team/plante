import 'package:plante/outside/backend/backend_product.dart';

class RequestedProductsResult {
  final List<BackendProduct> products;
  final int page;
  final bool lastPage;
  RequestedProductsResult(this.products, this.page, this.lastPage);
  bool get isEmpty => products.isEmpty;
}
