import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/photos/photos_taker.dart';
import 'package:plante/ui/product/display_product_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_input_products_lang_storage.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());

    final userParamsController = FakeUserParamsController();
    final user = UserParams((v) => v
      ..backendClientToken = '123'
      ..backendId = '321'
      ..name = 'Bob');
    await userParamsController.setUserParams(user);
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    GetIt.I.registerSingleton<ViewedProductsStorage>(
        ViewedProductsStorage(loadPersistentProducts: false));
    GetIt.I.registerSingleton<ShopsManager>(MockShopsManager());
    GetIt.I.registerSingleton<PermissionsManager>(MockPermissionsManager());
    GetIt.I.registerSingleton<Backend>(MockBackend());
    final userLocationManager = MockUserLocationManager();
    when(userLocationManager.lastKnownPositionInstant()).thenReturn(null);
    when(userLocationManager.lastKnownPosition()).thenAnswer((_) async => null);
    GetIt.I.registerSingleton<UserLocationManager>(userLocationManager);

    final photosTaker = MockPhotosTaker();
    GetIt.I.registerSingleton<PhotosTaker>(photosTaker);
    when(photosTaker.retrieveLostPhoto(any))
        .thenAnswer((realInvocation) async => null);

    GetIt.I.registerSingleton<InputProductsLangStorage>(
        FakeInputProductsLangStorage.fromCode(LangCode.en));
    GetIt.I.registerSingleton<UserLangsManager>(
        FakeUserLangsManager([LangCode.en]));
  });

  testWidgets('init page is shown when product is not filled',
      (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = Product((v) => v.barcode = '123');
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsOneWidget);
    expect(find.byType(DisplayProductPage), findsNothing);
  });

  testWidgets('init page is not shown when product is filled',
      (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = ProductLangSlice((v) => v
          ..barcode = '123'
          ..name = 'name'
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.community
          ..ingredientsText = '1, 2, 3'
          ..imageIngredients =
              Uri.file(File('./test/assets/img.jpg').absolute.path)
          ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path))
        .productForTests();
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsNothing);
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets(
      'init page is not shown when product is filled but lacks ingredients text',
      (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = ProductLangSlice((v) => v
          ..barcode = '123'
          ..name = 'name'
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.community
          ..ingredientsText = null // !!!!!!!!
          ..imageIngredients =
              Uri.file(File('./test/assets/img.jpg').absolute.path)
          ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path))
        .productForTests();
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsNothing);
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });

  testWidgets(
      'init_product_page is not shown when '
      'veg-statuses are filled by OFF', (WidgetTester tester) async {
    GetIt.I.registerSingleton<ProductsManager>(MockProductsManager());
    final initialProduct = ProductLangSlice((v) => v
          ..barcode = '123'
          ..name = 'name'
          ..veganStatus = VegStatus.negative
          ..veganStatusSource = VegStatusSource.open_food_facts // OFF!
          ..ingredientsText = '1, 2, 3'
          ..imageIngredients =
              Uri.file(File('./test/assets/img.jpg').absolute.path)
          ..imageFront = Uri.file(File('./test/assets/img.jpg').absolute.path))
        .productForTests();
    await tester.superPump(ProductPageWrapper.createForTesting(initialProduct));
    expect(find.byType(InitProductPage), findsNothing);
    expect(find.byType(DisplayProductPage), findsOneWidget);
  });
}
