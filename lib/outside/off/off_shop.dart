
class OffShop {
  final String id;
  final String? _name;
  final int? _products;

  OffShop(this.id, this._name, this._products);

  OffShop.fromJson(Map<String, dynamic> json) :
        id = json['id'].toString(),
        _name = json['name'] as String,
        _products = json['products'] as int;

  String get name {
    return _name != null ? _name! : '';
  }

  int get products {
    return _products != null ? _products! : 0;
  }
}

