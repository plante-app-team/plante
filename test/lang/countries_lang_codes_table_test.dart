import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/model/lang_code.dart';
import 'package:test/test.dart';

import '../z_fakes/fake_analytics.dart';

void main() {
  late FakeAnalytics analytics;
  late CountriesLangCodesTable table;

  setUp(() async {
    analytics = FakeAnalytics();
    table = CountriesLangCodesTable(analytics);
  });

  test('good scenario', () async {
    expect(table.countryCodeToLangCode('ru'), equals([LangCode.ru]));
    expect(
        table.countryCodeToLangCode('by'), equals([LangCode.be, LangCode.ru]));
    expect(table.countryCodeToLangCode('be'),
        equals([LangCode.nl, LangCode.fr, LangCode.de]));
    expect(analytics.allEvents(), equals([]));
  });

  test('bad scenario', () async {
    expect(table.countryCodeToLangCode('atata'), isNull);
    expect(analytics.wasEventSent('no_lang_code_for_country'), isTrue);
  });
}
