import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/result.dart';
import 'package:plante/contributions/user_contribution.dart';
import 'package:plante/contributions/user_contribution_type.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/products/contributed_by_user_products_storage.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/profile/components/contributed_by_user_products_widget.dart';

import '../../../stateful_stack_for_testing.dart';
import '../../../test_di_registry.dart';
import '../../../widget_tester_extension.dart';
import '../../../z_fakes/fake_products_obtainer.dart';
import '../../../z_fakes/fake_shared_preferences.dart';
import '../../../z_fakes/fake_shops_manager.dart';
import '../../../z_fakes/fake_user_contributions_manager.dart';
import '../../../z_fakes/fake_user_params_controller.dart';

void main() {
  late FakeProductsObtainer productsObtainer;
  late FakeUserParamsController userParamsController;
  late FakeUserContributionsManager userContributionsManager;
  late ContributedByUserProductsStorage storage;

  setUp(() async {
    await TestDiRegistry.register((r) async {
      r.register<ViewedProductsStorage>(ViewedProductsStorage());

      productsObtainer = FakeProductsObtainer();
      productsObtainer.unknownProductsGeneratorSimple = _makeProduct;
      r.register<ProductsObtainer>(productsObtainer);

      userParamsController = FakeUserParamsController();
      final user = UserParams((v) => v
        ..backendClientToken = '123'
        ..backendId = '321'
        ..name = 'Bob');
      await userParamsController.setUserParams(user);
      r.register<UserParamsController>(userParamsController);
      r.register<LatestCameraPosStorage>(
          LatestCameraPosStorage(FakeSharedPreferences().asHolder()));
      r.register<ShopsManager>(FakeShopsManager());
    });

    userContributionsManager = FakeUserContributionsManager();
    storage = ContributedByUserProductsStorage();
  });

  testWidgets('contributed by user products shown',
      (WidgetTester tester) async {
    final products = [
      _makeProduct('1'),
      _makeProduct('2'),
    ];
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[0].barcode),
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(222),
          barcode: products[1].barcode),
    ]);

    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController));

    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('products order', (WidgetTester tester) async {
    final products = [
      _makeProduct('1'),
      _makeProduct('2'),
    ];
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[0].barcode),
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(222),
          barcode: products[1].barcode),
    ]);
    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController,
        key: const Key('widget 1')));

    // More recent product is above of the older (Y coord is smaller).
    var center1 = tester.getCenter(find.text('Product 1'));
    var center2 = tester.getCenter(find.text('Product 2'));
    expect(center2.dy, lessThan(center1.dy));

    // Switch times of the contributions
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(222),
          barcode: products[0].barcode),
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[1].barcode),
    ]);
    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController,
        key: const Key('widget 2')));

    // More recent product is above of the older (Y coord is smaller).
    center1 = tester.getCenter(find.text('Product 1'));
    center2 = tester.getCenter(find.text('Product 2'));
    expect(center1.dy, lessThan(center2.dy));
  });

  testWidgets('duplicate products are removed (the older ones)',
      (WidgetTester tester) async {
    final products = [
      _makeProduct('1'),
      _makeProduct('2'),
    ];
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[0].barcode),
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(222),
          barcode: products[1].barcode),
      // First product again, but it's more recent
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(333),
          barcode: products[0].barcode),
    ]);
    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController));

    // Ensure only one of each products is present
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);

    // The recent Product 1 is expected to be present. We check it's recent
    // by checking it's above of the Product 2.
    final center1 = tester.getCenter(find.text('Product 1'));
    final center2 = tester.getCenter(find.text('Product 2'));
    expect(center1.dy, lessThan(center2.dy));
  });

  testWidgets('types of user contributions displayed',
      (WidgetTester tester) async {
    // A contribution for each of the contribution types
    userContributionsManager.setContributionsSimple_testing(UserContributionType
        .values
        .map((e) => UserContribution.create(
            e, dateTimeFromSecondsSinceEpoch(111),
            barcode: e.index.toString()))
        .toList());
    const expectedDisplayedContributionTypes = [
      UserContributionType.PRODUCT_ADDED_TO_SHOP,
      UserContributionType.PRODUCT_EDITED,
      UserContributionType.LEGACY_PRODUCT_EDITED,
    ];
    final unexpectedDisplayedContributionTypes = UserContributionType.values
        .where((e) => !expectedDisplayedContributionTypes.contains(e));

    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController));

    for (final expected in expectedDisplayedContributionTypes) {
      expect(find.text('Product ${expected.index}'), findsOneWidget);
    }
    for (final unexpected in unexpectedDisplayedContributionTypes) {
      expect(find.text('Product ${unexpected.index}'), findsNothing);
    }
  });

  testWidgets(
      'contributions are loaded (and reloaded) only when widget is shown',
      (WidgetTester tester) async {
    var products = [
      _makeProduct('1'),
    ];
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[0].barcode),
    ]);

    final wrapperStack = StatefulStackForTesting(
      tester: tester,
      children: [
        Container(color: Colors.white),
        ContributedByUserProductsWidget(userContributionsManager, storage,
            productsObtainer, userParamsController),
      ],
    );
    await tester.superPump(wrapperStack);

    // No one requested contributions yet
    expect(userContributionsManager.getContributionsCallsCount_testing(),
        equals(0));

    // Switch to the contributions widget
    await wrapperStack.switchStackToIndex(1);

    // Now the contributions are requested
    expect(userContributionsManager.getContributionsCallsCount_testing(),
        equals(1));
    // And displayed
    expect(find.text('Product 1'), findsOneWidget);

    // Change the contributions
    products = [
      _makeProduct('2'),
    ];
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[0].barcode),
    ]);

    // Switch from the contributions widget
    await wrapperStack.switchStackToIndex(0);

    // The widget is in the background - we don't expect new requests
    expect(userContributionsManager.getContributionsCallsCount_testing(),
        equals(1));

    // Switch to the contributions widget
    await wrapperStack.switchStackToIndex(1);

    // The widget went foreground - we expect another request to contributions
    expect(userContributionsManager.getContributionsCallsCount_testing(),
        equals(2));
    // And we expect the new contribution to be displayed instead of the old one
    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product 2'), findsOneWidget);
  });

  testWidgets('product click', (WidgetTester tester) async {
    final p1 = _makeProduct('1');
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: p1.barcode),
    ]);

    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController));

    expect(find.byKey(const Key('display_product_page')), findsNothing);

    await tester.tap(find.text('Product 1'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('display_product_page')), findsOneWidget);
  });

  testWidgets('no contributed products', (WidgetTester tester) async {
    // No contributions!
    userContributionsManager.setContributionsSimple_testing(const []);

    var context = await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController,
        key: const Key('key1')));

    expect(
        find.text(context
            .strings.contributed_by_user_products_widget_no_products_hint),
        findsOneWidget);

    // There's a contribution now!
    final products = [
      _makeProduct('1'),
    ];
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[0].barcode),
    ]);

    context = await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController,
        key: const Key('key2')));

    expect(
        find.text(context
            .strings.contributed_by_user_products_widget_no_products_hint),
        findsNothing);
  });

  testWidgets('products loading error and reloading',
      (WidgetTester tester) async {
    // Error!
    userContributionsManager
        .setContributionsResult_testing(Err(BackendError.other()));

    final context = await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController));

    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);

    // No errors from now on!
    final products = [
      _makeProduct('1'),
    ];
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: products[0].barcode),
    ]);

    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);
    expect(find.text('Product 1'), findsNothing);

    await tester.superTap(find.text(context.strings.global_try_again));

    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
    expect(find.text('Product 1'), findsOneWidget);
  });

  testWidgets(
      'products from persistent storage are used before they are loaded from network',
      (WidgetTester tester) async {
    final p1 = _makeProduct('1');
    final p2 = _makeProduct('2');
    final p3 = _makeProduct('3');

    await storage.setProducts([p1, p3]);

    final completer = Completer<Result<List<UserContribution>, BackendError>>();
    userContributionsManager.setContributions_testing(completer.future);

    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController));
    // Products from persistent storage are loaded first
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.text('Product 2'), findsNothing);
    expect(find.text('Product 3'), findsOneWidget);

    completer.complete(Ok([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: p2.barcode),
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(222),
          barcode: p3.barcode),
    ]));
    await tester.pumpAndSettle();

    // Products from the backend are shown as soon as they're loaded
    expect(find.text('Product 1'), findsNothing);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('Product 3'), findsOneWidget);
  });

  testWidgets(
      'products are stored persistently when they are loaded from network',
      (WidgetTester tester) async {
    // The backend has some contributions
    final p1 = _makeProduct('1');
    final p2 = _makeProduct('2');
    userContributionsManager.setContributionsSimple_testing([
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(111),
          barcode: p1.barcode),
      UserContribution.create(UserContributionType.PRODUCT_EDITED,
          dateTimeFromSecondsSinceEpoch(222),
          barcode: p2.barcode),
    ]);

    // But no products are stored persistently yet
    expect(storage.getProducts(), isEmpty);

    await tester.superPump(ContributedByUserProductsWidget(
        userContributionsManager,
        storage,
        productsObtainer,
        userParamsController));

    // The backend contributions are now stored persistently
    expect(storage.getProducts(), equals([p1, p2]));
  });
}

Product _makeProduct(String barcode) {
  return ProductLangSlice((e) => e
    ..barcode = barcode
    ..name = 'Product $barcode'
    ..imageFront = Uri.file('/tmp/asd')
    ..imageIngredients = Uri.file('/tmp/asd')
    ..ingredientsText = 'beans'
    ..veganStatus = VegStatus.positive
    ..veganStatusSource = VegStatusSource.community).productForTests();
}
