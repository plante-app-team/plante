import 'package:plante/model/country.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  test('test is country enabled country list', () async {
    expect(Country.isEnabledCountry(Country.be.name), isTrue);
  });

  test('test is not country enabled country list', () async {
    expect(Country.isEnabledCountry(Country.af.name), isFalse);
  });

}