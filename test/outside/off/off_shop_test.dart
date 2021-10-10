import 'package:plante/outside/off/off_shop.dart';
import 'package:test/test.dart';

void main() {
  test('test from map to offShop', () async {
    final Map<String, dynamic> json = {
      'id' : 'shopId',
      'name' : 'Delhaize',
      'products' : 100
    };
    final OffShop shop = OffShop.fromJson(json);
    expect(shop.id,equals('shopId'));
    expect(shop.name,equals('Delhaize'));
    expect(shop.products,equals(100));
  });
}