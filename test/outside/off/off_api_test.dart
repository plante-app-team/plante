import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:openfoodfacts/utils/ProductListQueryConfiguration.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:test/test.dart';

import '../../z_fakes/fake_settings.dart';

void main() {
  late OffApi offApi;

  setUp(() async {
    offApi = OffApi(FakeSettings());
  });

  test('very fragile getProducts test', () async {
    final barcodes = [
      '4810410075316',
      '4680019562018',
      '4650057962767',
      '4606038053801',
      '4605825003791',
      '4601481831907',
      '4604248018269',
      '4607056943990',
      '4607018913788',
      '4607018913849',
      '4640071950192',
      '4606038066177',
      '8001300303503',
      '7340011499527',
      '4600699501398',
      '8595564502203',
      '8710400339977',
      '8718885890082',
      '4607015232578',
      '4607035890574',
      '2100100098506',
      '3017620422003',
      '4604248011949',
      '4810450001962',
      '4670008494383',
      '4601172231269',
      '4600699505426',
      '4690388108656',
      '5900020023315',
      '4607124142409',
      '4600452020487',
      '5900617003454',
      '4000417025005',
      '4680046724540',
      '4680019563442',
      '4627107450086',
      '0016229906436',
      '0016229906207',
      '5449000027474',
      '4600080282004',
      '4612742721165',
      '9001414603703',
      '4607010735548',
      '4660043853740',
      '4607061256412',
      '4602248010245',
      '4605932001284',
      '4607124141259',
      '4607005400185',
      '8410313323215'
    ];

    final obtainedBarcodes = <String>[];
    var page = 1;
    while (true) {
      final configuration = ProductListQueryConfiguration(barcodes,
          page: page, sortOption: off.SortOption.CREATED);

      final result = await offApi.getProductList(configuration);
      if (result.products == null || result.products!.isEmpty) {
        break;
      }
      final newBarcodes = result.products!.map((e) => e.barcode!);
      expect(newBarcodes.any(obtainedBarcodes.contains), isFalse);
      obtainedBarcodes.addAll(newBarcodes);
      page += 1;
    }
    // We want to test pagination mechanism so we expect >1 pages
    expect(page, greaterThan(1));
    expect(obtainedBarcodes.toSet(), equals(barcodes.toSet()));
  });
}
