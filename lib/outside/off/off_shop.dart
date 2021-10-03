
class OffShop {
  final String id;
  final bool? _known;
  final String? _name;
  final int? _products;
  final String? _url;

  OffShop(this.id, this._known, this._name, this._products, this._url);

  OffShop.fromJson(Map<String, dynamic> json) :
        id = json['_id'].toString(),
        _name = json['name'] as String,
        _known = json['known'] == '0' ? false : true,
        _products = json['products'] as int,
        _url = json['url'] as String;
}
