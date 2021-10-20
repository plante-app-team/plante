import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import 'products_manager_tests_commons.dart';

void main() {
  late ProductsManagerTestCommons commons;
  late MockOffApi offApi;
  late MockBackend backend;
  late ProductsManager productsManager;

  setUp(() async {
    commons = await ProductsManagerTestCommons.create();
    offApi = commons.offApi;
    backend = commons.backend;
    productsManager = commons.productsManager;
  });

  void setUpOffProducts(List<off.Product> products) {
    commons.setUpOffProducts(products);
  }

  test('ingredients extraction successful', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async =>
        const off.OcrIngredientsResult(
            status: 0, ingredientsTextFromImage: 'lemon, water'));

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.unwrap().ingredients, equals('lemon, water'));
  });

  test('ingredients extraction with product update fail', () async {
    when(offApi.extractIngredients(any, any, any)).thenAnswer((_) async =>
        const off.OcrIngredientsResult(
            status: 0, ingredientsTextFromImage: 'lemon, water'));

    when(offApi.saveProduct(any, any))
        .thenAnswer((_) async => off.Status(error: 'oops'));

    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.isErr, isTrue);
  });

  test('ingredients extraction fail', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    when(offApi.extractIngredients(any, any, any))
        .thenAnswer((_) async => const off.OcrIngredientsResult(status: 1));

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.unwrap().product, isNotNull);
    expect(result.unwrap().ingredients, isNull);
  });

  test('ingredients extraction network error', () async {
    final product = ProductLangSlice((v) => v
      ..lang = LangCode.ru
      ..barcode = '123'
      ..name = 'name'
      ..imageIngredients = Uri.file('/tmp/img2.jpg')).productForTests();

    when(offApi.extractIngredients(any, any, any))
        .thenAnswer((_) async => throw const SocketException(''));

    final result = await productsManager.updateProductAndExtractIngredients(
        product, LangCode.ru);
    expect(result.unwrapErr(), equals(ProductsManagerError.NETWORK_ERROR));
  });

  test('barcode from off is used', () async {
    const badBarcode = '0000000000123';
    const goodBarcode = '123';
    setUpOffProducts([
      off.Product.fromJson({'code': goodBarcode, 'product_name_ru': 'name'})
    ]);

    final productRes =
        await productsManager.getProduct(badBarcode, [LangCode.ru]);
    final product = productRes.unwrap();

    // Verify received product
    expect(product!.barcode, equals(goodBarcode));
    // Verify good barcode is asked from the backed
    verify(backend.requestProducts([goodBarcode], any)).called(1);
  });
}
