import 'package:mockito/mockito.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/base/result.dart';
import 'package:plante/contributions/user_contribution.dart';
import 'package:plante/contributions/user_contribution_type.dart';
import 'package:plante/contributions/user_contributions_manager.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/backend/user_report_data.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/products/products_manager.dart';
import 'package:test/test.dart';

import '../common_mocks.mocks.dart';
import '../z_fakes/fake_shops_manager.dart';

void main() {
  late MockBackend backend;
  late List<ProductsManagerObserver> productsManagerObservers;
  late MockProductsManager productsManager;
  late List<UserReportsMakerObserver> userReportsMakerObservers;
  late MockUserReportsMaker userReportsMaker;
  late FakeShopsManager shopsManager;

  late List<UserContribution> backendContributions;

  late UserContributionsManager userContributionsManager;

  setUp(() {
    backend = MockBackend();
    productsManager = MockProductsManager();
    shopsManager = FakeShopsManager();
    userReportsMaker = MockUserReportsMaker();

    productsManagerObservers = [];
    when(productsManager.addObserver(any)).thenAnswer((invc) {
      productsManagerObservers
          .add(invc.positionalArguments[0] as ProductsManagerObserver);
    });

    userReportsMakerObservers = [];
    when(userReportsMaker.addObserver(any)).thenAnswer((invc) {
      userReportsMakerObservers
          .add(invc.positionalArguments[0] as UserReportsMakerObserver);
    });

    backendContributions = <UserContribution>[];
    when(backend.requestUserContributions(any, any))
        .thenAnswer((_) async => Ok(backendContributions));

    userContributionsManager = UserContributionsManager(
        backend, productsManager, shopsManager, userReportsMaker);
  });

  test('backend data used', () async {
    backendContributions.add(UserContribution.create(
        UserContributionType.PRODUCT_EDITED,
        dateTimeFromSecondsSinceEpoch(1234567),
        barcode: '123321'));
    backendContributions.add(UserContribution.create(
        UserContributionType.PRODUCT_ADDED_TO_SHOP,
        dateTimeFromSecondsSinceEpoch(1234566),
        barcode: '123321',
        osmUID: OsmUID.parse('1:123321')));

    expect((await userContributionsManager.getContributions()).unwrap(),
        equals(backendContributions));
  });

  test('backend queried only once, by the first getContributions call',
      () async {
    verifyZeroInteractions(backend);

    expect((await userContributionsManager.getContributions()).isOk, isTrue);
    verify(backend.requestUserContributions(any, any)).called(1);

    expect((await userContributionsManager.getContributions()).isOk, isTrue);
    verifyNever(backend.requestUserContributions(any, any));
  });

  test('backend queried twice if the first request failed', () async {
    when(backend.requestUserContributions(any, any))
        .thenAnswer((_) async => Err(BackendError.other()));
    expect((await userContributionsManager.getContributions()).isErr, isTrue);

    when(backend.requestUserContributions(any, any))
        .thenAnswer((_) async => Ok(backendContributions));
    expect((await userContributionsManager.getContributions()).isOk, isTrue);

    verify(backend.requestUserContributions(any, any)).called(2);
  });

  test('all contribution types are requested from backend', () async {
    await userContributionsManager.getContributions();
    final requestedContributions =
        verify(backend.requestUserContributions(any, captureAny)).captured.first
            as Iterable<UserContributionType>;

    expect(requestedContributions.toSet(),
        equals(UserContributionType.values.toSet()));
  });

  test('all contribution types are supported', () async {
    // If new contribution type is added, the manager must support its observing
    expect(UserContributionsManager.SUPPORTED_CONTRIBUTIONS,
        equals(UserContributionType.values));
  });

  test('listens to products editing', () async {
    // First request will load data from the backend
    await userContributionsManager.getContributions();

    productsManagerObservers
        .forEach((o) => o.onProductEdited(ProductLangSlice((e) => e
          ..barcode = '222'
          ..name = 'Product name').productForTests()));

    final contributions =
        (await userContributionsManager.getContributions()).unwrap();
    expect(contributions.length, equals(1));

    expect(contributions.first.time.difference(DateTime.now()).inSeconds,
        lessThanOrEqualTo(1));
    expect(
        contributions.first.type, equals(UserContributionType.PRODUCT_EDITED));
    expect(contributions.first.barcode, equals('222'));
    expect(contributions.first.osmUID, isNull);
  });

  test('listens to user reports', () async {
    // First request will load data from the backend
    await userContributionsManager.getContributions();

    userReportsMakerObservers.forEach(
        (o) => o.onUserReportMade(ProductReportData('my report', '333')));
    userReportsMakerObservers.forEach(
        (o) => o.onUserReportMade(NewsPieceReportData('my report', '123')));

    final contributions =
        (await userContributionsManager.getContributions()).unwrap();
    expect(contributions.length, equals(2));

    for (final contribution in contributions) {
      expect(contribution.time.difference(DateTime.now()).inSeconds,
          lessThanOrEqualTo(1));
    }

    expect(contributions[0].type, equals(UserContributionType.REPORT_WAS_MADE));
    expect(contributions[0].barcode, equals('333'));
    expect(contributions[0].osmUID, isNull);
    expect(contributions[1].type, equals(UserContributionType.REPORT_WAS_MADE));
    expect(contributions[1].barcode, isNull);
    expect(contributions[1].osmUID, isNull);
  });

  test('listens to products being added to shops', () async {
    // First request will load data from the backend
    await userContributionsManager.getContributions();

    final product = ProductLangSlice((e) => e
      ..barcode = '444'
      ..name = 'Product name').productForTests();
    final shops = [
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:1')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Spar'))),
      Shop((e) => e
        ..osmShop.replace(OsmShop((e) => e
          ..osmUID = OsmUID.parse('1:2')
          ..longitude = 11
          ..latitude = 11
          ..name = 'Kroger'))),
    ];

    await shopsManager.putProductToShops(
        product, shops, ProductAtShopSource.OFF_SUGGESTION);

    final contributions =
        (await userContributionsManager.getContributions()).unwrap();
    expect(contributions.length, equals(2));

    expect(contributions[0].time.difference(DateTime.now()).inSeconds,
        lessThanOrEqualTo(1));
    expect(contributions[0].type,
        equals(UserContributionType.PRODUCT_ADDED_TO_SHOP));
    expect(contributions[0].barcode, equals('444'));
    expect(contributions[0].osmUID, equals(OsmUID.parse('1:1')));
    expect(contributions[1].time.difference(DateTime.now()).inSeconds,
        lessThanOrEqualTo(1));
    expect(contributions[1].type,
        equals(UserContributionType.PRODUCT_ADDED_TO_SHOP));
    expect(contributions[1].barcode, equals('444'));
    expect(contributions[1].osmUID, equals(OsmUID.parse('1:2')));
  });

  test('listens to shops being created', () async {
    // First request will load data from the backend
    await userContributionsManager.getContributions();

    final createdShop = await shopsManager.createShop(
        name: 'Spar', coord: Coord(lat: 1, lon: 1), type: ShopType.bakery);

    final contributions =
        (await userContributionsManager.getContributions()).unwrap();
    expect(contributions.length, equals(1));

    expect(contributions.first.time.difference(DateTime.now()).inSeconds,
        lessThanOrEqualTo(1));
    expect(contributions.first.type, equals(UserContributionType.SHOP_CREATED));
    expect(contributions.first.barcode, isNull);
    expect(contributions.first.osmUID, equals(createdShop.unwrap().osmUID));
  });
}
