import 'package:openfoodfacts/model/SearchResult.dart';
import 'package:plante/model/product.dart';

class OffShop {
  final String id;
  final String? _name;
  final int? _products;
  late SearchResult? latestSearchResult;
  final List<Product>? _veganProducts;

  OffShop(this.id, this._name, this._products, this.latestSearchResult, this._veganProducts);

  OffShop.fromJson(Map<String, dynamic> json)
      : id = json['id'].toString(),
        _name = json['name'] as String,
        _products = json['products'] as int,
        latestSearchResult = null,
        _veganProducts = [];

  String get name {
    return _name != null ? _name! : '';
  }

  int get products {
    return _products != null ? _products! : 0;
  }

  List<Product> get veganProducts {
    return _veganProducts != null ? _veganProducts! : [];
  }

  bool hasVeganProducts() {
    return latestSearchResult != null ? latestSearchResult!.count! >= 0 : false;
  }
}
