import 'package:built_collection/built_collection.dart';
import 'package:openfoodfacts/model/Product.dart' as off;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:plante/base/result.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/products/products_manager.dart';
import 'package:test/test.dart';

import 'products_manager_tests_commons.dart';

void main() {
  late ProductsManagerTestCommons commons;
  late ProductsManager productsManager;

  setUp(() async {
    commons = await ProductsManagerTestCommons.create();
    productsManager = commons.productsManager;
  });

  void setUpOffProducts(List<off.Product> products) {
    commons.setUpOffProducts(products);
  }

  void setUpBackendProducts(
      Result<List<BackendProduct>, BackendError> productsRes) {
    commons.setUpBackendProducts(productsRes);
  }

  test('off ingredients analysis parsing', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'voda',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    setUpOffProducts([offProduct]);

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(
        product!.ingredientsAnalyzed,
        equals(BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'voda'
            ..veganStatus = VegStatus.possible)
        ])));
  });

  test('off multiple ingredients analysis parsing order 1', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'voda',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        },
        {
          'vegan': 'maybe',
          'vegetarian': 'no',
          'text': 'salt',
          'id': 'en:salt',
        },
      ],
      'ingredients_tags': ['en:water', 'en:salt'],
      'ingredients_tags_ru': ['voda', 'sol'],
    });
    setUpOffProducts([offProduct]);

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(
        product!.ingredientsAnalyzed,
        equals(BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'voda'
            ..veganStatus = VegStatus.possible),
          Ingredient((v) => v
            ..name = 'sol'
            ..veganStatus = VegStatus.possible)
        ])));
  });

  test('off multiple ingredients analysis parsing order 2', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'voda',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'no',
          'text': 'salt',
          'id': 'en:salt',
        },
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        },
      ],
      'ingredients_tags': ['en:water', 'en:salt'],
      'ingredients_tags_ru': ['voda', 'sol'],
    });
    setUpOffProducts([offProduct]);

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(
        product!.ingredientsAnalyzed,
        equals(BuiltList<Ingredient>([
          Ingredient((v) => v
            ..name = 'sol'
            ..veganStatus = VegStatus.possible),
          Ingredient((v) => v
            ..name = 'voda'
            ..veganStatus = VegStatus.possible),
        ])));
  });

  test(
      'off ingredients analysis is not used when ingredients text is not provided',
      () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      // 'ingredients_text_ru': null, // NOTE: no text
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    setUpOffProducts([offProduct]);

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.ingredientsAnalyzed, isNull);
  });

  test(
      'if vegan status exists both on backend and OFF then '
      'from backend is used', () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'water',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    setUpOffProducts([offProduct]);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = VegStatusSource.moderator.name);
    setUpBackendProducts(Ok([backendProduct]));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.veganStatus, equals(VegStatus.negative));
    expect(product.veganStatusSource, equals(VegStatusSource.moderator));
  });

  test('invalid veg statuses from server are treated as community', () async {
    final offProduct = off.Product.fromJson({'code': '123'});
    setUpOffProducts([offProduct]);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = VegStatus.negative.name
      ..veganStatusSource = '${VegStatusSource.moderator.name}woop');
    setUpBackendProducts(Ok([backendProduct]));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.veganStatus, equals(VegStatus.negative));
    expect(product.veganStatusSource, equals(VegStatusSource.community));
  });

  test('invalid veg statuses from server are treated as if they do not exist',
      () async {
    final offProduct = off.Product.fromJson({'code': '123'});
    setUpOffProducts([offProduct]);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = '${VegStatus.negative.name}woop'
      ..veganStatusSource = VegStatusSource.moderator.name);
    setUpBackendProducts(Ok([backendProduct]));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.veganStatus, isNull);
  });

  test('invalid veg statuses from server are treated as if they do not exist',
      () async {
    final offProduct = off.Product.fromJson({'code': '123'});
    setUpOffProducts([offProduct]);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = '${VegStatus.negative.name}woop'
      ..veganStatusSource = VegStatusSource.moderator.name);
    setUpBackendProducts(Ok([backendProduct]));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.veganStatus, isNull);
  });

  test('if backend veg statuses parsing failed then analysis is used',
      () async {
    final offProduct = off.Product.fromJson({
      'code': '123',
      'ingredients_text_ru': 'water',
      'ingredients': [
        {
          'vegan': 'maybe',
          'vegetarian': 'yes',
          'text': 'water',
          'id': 'en:water',
        }
      ],
      'ingredients_tags': ['en:water'],
      'ingredients_tags_ru': ['voda'],
    });
    setUpOffProducts([offProduct]);

    final backendProduct = BackendProduct((v) => v
      ..barcode = '123'
      ..veganStatus = '${VegStatus.negative.name}woop'
      ..veganStatusSource = VegStatusSource.moderator.name);
    setUpBackendProducts(Ok([backendProduct]));

    final productRes = await productsManager.getProduct('123', [LangCode.ru]);
    final product = productRes.unwrap();
    expect(product!.veganStatus, VegStatus.possible);
    expect(product.veganStatusSource, VegStatusSource.open_food_facts);
  });
}
