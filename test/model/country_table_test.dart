import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/model/country.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/model/country_table.dart';
import 'package:test/test.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  setUp(() {});

  test('Get country that is listed in the countryTable', () async {
    final Country? belgium = CountryTable.getCountry(CountryCode.BELGIUM);
    expect(belgium != null, true);
    expect(belgium!.iso2Code, CountryCode.BELGIUM);
  });

  test('Country not found in the countryTable', () async {
    final Country? country = CountryTable.getCountry('dz');
    expect(country == null, true);
  });
}
