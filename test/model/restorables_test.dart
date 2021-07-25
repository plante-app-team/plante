import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/product_lang_slice_restorable.dart';
import 'package:plante/model/product_restorable.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_restorable.dart';
import 'package:plante/model/shops_list_restorable.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';

import '../widget_tester_extension.dart';

// ignore: must_be_immutable
class _TestWidget extends StatefulWidget {
  __TestWidgetState? state;
  _TestWidget({Key? key}) : super(key: key);

  @override
  __TestWidgetState createState() {
    state = __TestWidgetState();
    return state!;
  }

  void register(RestorableProperty<Object?> property, String restorationId) {
    // ignore: invalid_use_of_protected_member
    state!.registerForRestoration(property, restorationId);
  }
}
class __TestWidgetState extends State<_TestWidget> with RestorationMixin {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  String? get restorationId => 'cool id';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
  }
}

void main() {
  setUp(() async {
  });

  testWidgets('ProductRestorable', (WidgetTester tester) async {
    final widget = _TestWidget();
    await tester.superPump(widget);

    final product = Product((e) => e
      ..barcode = '123'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.community
      ..nameLangs.addAll({ LangCode.en: 'hello there', LangCode.ru: 'Privet tut'})
      ..brands.addAll(['Horns', 'Hooves'])
      ..ingredientsTextLangs.addAll({ LangCode.en: 'Water, lemon', LangCode.ru: 'Voda, lemon' })
      ..ingredientsAnalyzedLangs.addAll({LangCode.en: BuiltList.from([
        Ingredient((v) => v
          ..name = 'water'
          ..vegetarianStatus = VegStatus.possible),
        Ingredient((v) => v
          ..name = 'lemon'
          ..vegetarianStatus = VegStatus.positive)])})
      ..imageFrontLangs.addAll({
        LangCode.en: Uri.parse('https://en.wikipedia.org/static/apple-touch/wikipedia.png'),
        LangCode.ru: Uri.parse('https://en.wikipedia.org/static/apple-touch/wikipedia.png') })
      ..imageFrontThumbLangs.addAll({ LangCode.en: Uri.parse('https://en.wikipedia.org/static/apple-touch/wikipedia.png')})
      ..imageIngredientsLangs.addAll({ LangCode.en: Uri.parse('https://en.wikipedia.org/static/apple-touch/wikipedia.png')})
    );

    final restorable = ProductRestorable(Product.empty);
    widget.register(restorable, 'restorable');
    restorable.value = product;

    final restored = ProductRestorable(Product.empty);
    widget.register(restored, 'restored');
    restored.value = restored.fromPrimitives(restorable.toPrimitives());

    expect(restored.value, equals(restorable.value));
  });

  testWidgets('ProductLangSliceRestorable', (WidgetTester tester) async {
    final widget = _TestWidget();
    await tester.superPump(widget);

    final slice = ProductLangSlice((e) => e
      ..barcode = '123'
      ..veganStatus = VegStatus.positive
      ..veganStatusSource = VegStatusSource.open_food_facts
      ..vegetarianStatus = VegStatus.negative
      ..vegetarianStatusSource = VegStatusSource.community
      ..name = 'hello there'
      ..brands.addAll(['Horns', 'Hooves'])
      ..ingredientsText = 'Water, lemon'
      ..ingredientsAnalyzed.addAll([
        Ingredient((v) => v
          ..name = 'water'
          ..vegetarianStatus = VegStatus.possible),
        Ingredient((v) => v
          ..name = 'lemon'
          ..vegetarianStatus = VegStatus.positive)])
      ..imageFront = Uri.parse('https://en.wikipedia.org/static/apple-touch/wikipedia.png')
      ..imageFrontThumb = Uri.parse('https://en.wikipedia.org/static/apple-touch/wikipedia.png')
      ..imageIngredients = Uri.parse('https://en.wikipedia.org/static/apple-touch/wikipedia.png')
    );

    final restorable = ProductLangSliceRestorable(
        ProductLangSlice.from(Product.empty, LangCode.en));
    widget.register(restorable, 'restorable');
    restorable.value = slice;

    final restored = ProductLangSliceRestorable(
        ProductLangSlice.from(Product.empty, LangCode.en));
    widget.register(restored, 'restored');
    restored.value = restored.fromPrimitives(restorable.toPrimitives());

    expect(restored.value, equals(restorable.value));
  });

  testWidgets('ShopRestorable', (WidgetTester tester) async {
    final widget = _TestWidget();
    await tester.superPump(widget);

    final shop = Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = '1'
        ..longitude = 11
        ..latitude = 11
        ..name = 'Spar'))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = '1'
        ..productsCount = 2)));

    final restorable = ShopRestorable(Shop.empty);
    widget.register(restorable, 'restorable');
    restorable.value = shop;

    final restored = ShopRestorable(Shop.empty);
    widget.register(restored, 'restored');
    restored.value = restored.fromPrimitives(restorable.toPrimitives());

    expect(restored.value, equals(restorable.value));
  });

  testWidgets('ShopsListRestorable', (WidgetTester tester) async {
    final widget = _TestWidget();
    await tester.superPump(widget);

    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '1'
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '1'
          ..productsCount = 1))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmId = '2'
          ..longitude = 12
          ..latitude = 12
          ..name = 'Spar2'))
        ..backendShop.replace(BackendShop((e) => e
          ..osmId = '2'
          ..productsCount = 2))),
    ];

    final restorable = ShopsListRestorable(const []);
    widget.register(restorable, 'restorable');
    restorable.value = shops;

    final restored = ShopsListRestorable(const []);
    widget.register(restored, 'restored');
    restored.value = restored.fromPrimitives(restorable.toPrimitives());

    expect(restored.value, equals(restorable.value));
  });
}
