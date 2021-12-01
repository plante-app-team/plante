import 'package:flutter_test/flutter_test.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_wrapper.dart';

void main() {
  late OffShopsListWrapper offShopsListWrapper;

  final offShops = [
    OffShop((e) => e
      ..id = 'spar'
      ..name = 'Spar'
      ..productsCount = 2
      ..country = 'ru'),
    OffShop((e) => e
      ..id = 'auchan'
      ..name = 'Auchan'
      ..productsCount = 2
      ..country = 'ru'),
  ];

  setUp(() async {
    offShopsListWrapper = await OffShopsListWrapper.create(offShops);
  });

  tearDown(() {
    offShopsListWrapper.dispose();
  });

  test('stores given shops', () async {
    expect(offShopsListWrapper.shops, equals(offShops));
  });

  test('finds appropriate shops', () async {
    var result = await offShopsListWrapper.findAppropriateShopsFor(['spar']);
    expect(
        result,
        equals({
          'spar': offShops[0],
        }));

    result = await offShopsListWrapper.findAppropriateShopsFor(['auchan']);
    expect(
        result,
        equals({
          'auchan': offShops[1],
        }));

    result =
        await offShopsListWrapper.findAppropriateShopsFor(['spar', 'aUcHaN']);
    expect(
        result,
        equals({
          'spar': offShops[0],
          'aUcHaN': offShops[1],
        }));
  });
}
