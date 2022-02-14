import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:openfoodfacts/model/OcrIngredientsResult.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/products/products_manager.dart';
import 'package:plante/products/products_manager_error.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import 'products_manager_tests_commons.dart';

void main() {
  late ProductsManagerTestCommons commons;
  late MockOffApi offApi;
  late ProductsManager productsManager;

  setUp(() async {
    commons = await ProductsManagerTestCommons.create();
    offApi = commons.offApi;
    productsManager = commons.productsManager;
  });

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
}
