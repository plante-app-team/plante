import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/map/displayed_distance_units_manager.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_caching_user_address_pieces_obtainer.dart';
import '../../z_fakes/fake_settings.dart';

void main() {
  late FakeCachingUserAddressPiecesObtainer userAddressObtainer;
  late FakeSettings settings;
  late DisplayedDistanceUnitsManager displayedDistanceManager;

  setUp(() async {
    userAddressObtainer = FakeCachingUserAddressPiecesObtainer();
    settings = FakeSettings();
    displayedDistanceManager =
        DisplayedDistanceUnitsManager(userAddressObtainer, settings);
  });

  void expectMiles(BuildContext context) {
    expect(displayedDistanceManager.metersToStr(99999, context),
        contains(context.strings.global_miles));
    expect(displayedDistanceManager.metersToStr(99999, context),
        isNot(contains(context.strings.global_kilometers)));
  }

  void expectKilometers(BuildContext context) {
    expect(displayedDistanceManager.metersToStr(99999, context),
        isNot(contains(context.strings.global_miles)));
    expect(displayedDistanceManager.metersToStr(99999, context),
        contains(context.strings.global_kilometers));
  }

  testWidgets('miles are used for certain countries',
      (WidgetTester tester) async {
    final context = await tester.superPump(Container());
    final countries = {
      'be',
      'fr',
      'de',
      'nl',
      'lu',
      'es',
      'pt',
      'it',
      'gr',
      'pl',
      'dk',
      'no',
      'se',
      'gb',
      'uk',
      'ru',
      'us',
    };
    for (final milesCountry in DisplayedDistanceUnitsManager.MILES_COUNTRIES) {
      expect(countries, contains(milesCountry));
    }

    for (final country in countries) {
      userAddressObtainer.setResultFor(UserAddressType.USER_LOCATION,
          UserAddressPiece.COUNTRY_CODE, country);

      displayedDistanceManager =
          DisplayedDistanceUnitsManager(userAddressObtainer, settings);
      await displayedDistanceManager.fullyInited;

      if (DisplayedDistanceUnitsManager.MILES_COUNTRIES.contains(country)) {
        expectMiles(context);
      } else {
        expectKilometers(context);
      }
    }
  });

  testWidgets('kilometers are used before initialization is finished',
      (WidgetTester tester) async {
    final context = await tester.superPump(Container());
    userAddressObtainer.setResultFor(
        UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE,
        DisplayedDistanceUnitsManager.MILES_COUNTRIES.first);

    expectKilometers(context);
    await tester.pumpAndSettle();
    expectMiles(context);
  });

  testWidgets('when user country changes, distance unit updates asynchronously',
      (WidgetTester tester) async {
    userAddressObtainer.setResultFor(
        UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE,
        DisplayedDistanceUnitsManager.MILES_COUNTRIES.first);
    displayedDistanceManager =
        DisplayedDistanceUnitsManager(userAddressObtainer, settings);
    final context = await tester.superPump(Container());
    await tester.pumpAndSettle();

    expectMiles(context);

    userAddressObtainer.setResultFor(UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE, CountryCode.RUSSIA);

    // Still miles
    expectMiles(context);
    expectMiles(context);
    expectMiles(context);

    await tester.pumpAndSettle();

    // Now kilometers
    expectKilometers(context);
  });

  testWidgets('miles setting has priority over user country',
      (WidgetTester tester) async {
    userAddressObtainer.setResultFor(
        UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE,
        DisplayedDistanceUnitsManager.MILES_COUNTRIES.first);
    displayedDistanceManager =
        DisplayedDistanceUnitsManager(userAddressObtainer, settings);
    final context = await tester.superPump(Container());
    await tester.pumpAndSettle();

    expectMiles(context);
    await settings.setDistanceInMiles(false);
    expectKilometers(context);
  });

  testWidgets('kilometers to meters switch', (WidgetTester tester) async {
    final context = await tester.superPump(Container());
    await tester.pumpAndSettle();

    expect(displayedDistanceManager.metersToStr(1000, context),
        contains(context.strings.global_kilometers));
    expect(displayedDistanceManager.metersToStr(1000, context),
        isNot(contains(context.strings.global_meters)));

    expect(displayedDistanceManager.metersToStr(999, context),
        isNot(contains(context.strings.global_kilometers)));
    expect(displayedDistanceManager.metersToStr(999, context),
        contains(context.strings.global_meters));
  });

  testWidgets('miles to feet switch', (WidgetTester tester) async {
    userAddressObtainer.setResultFor(
        UserAddressType.USER_LOCATION,
        UserAddressPiece.COUNTRY_CODE,
        DisplayedDistanceUnitsManager.MILES_COUNTRIES.first);
    displayedDistanceManager =
        DisplayedDistanceUnitsManager(userAddressObtainer, settings);
    final context = await tester.superPump(Container());
    await tester.pumpAndSettle();

    final milesToMeters = (double miles) => miles * 1609.34;

    expect(displayedDistanceManager.metersToStr(milesToMeters(0.11), context),
        contains(context.strings.global_miles));
    expect(displayedDistanceManager.metersToStr(milesToMeters(0.11), context),
        isNot(contains(context.strings.global_feet)));

    expect(displayedDistanceManager.metersToStr(milesToMeters(0.09), context),
        isNot(contains(context.strings.global_miles)));
    expect(displayedDistanceManager.metersToStr(milesToMeters(0.09), context),
        contains(context.strings.global_feet));
  });
}
