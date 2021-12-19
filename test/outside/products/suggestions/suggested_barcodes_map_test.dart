import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/products/suggestions/suggested_barcodes_map.dart';
import 'package:test/test.dart';

void main() {
  test('equals', () {
    final map1 = SuggestedBarcodesMap({
      OsmUID.parse('1:1'): ['123', '234'],
      OsmUID.parse('1:2'): ['567', '789'],
    });
    final map2 = SuggestedBarcodesMap({
      OsmUID.parse('1:1'): ['123', '234'],
      OsmUID.parse('1:2'): ['567', '789'],
    });
    expect(map1.equals(map2), isTrue);

    map2[OsmUID.parse('1:2')] = ['567', '789', '132'];
    expect(map1.equals(map2), isFalse);

    final map3 = SuggestedBarcodesMap({
      OsmUID.parse('1:1'): ['123', '234'],
      OsmUID.parse('1:2'): ['567', '789'],
    });
    expect(map1.equals(map3), isTrue);

    map3[OsmUID.parse('1:2')] = ['1'];
    expect(map1.equals(map3), isFalse);
  });

  test('operator []', () {
    final map = SuggestedBarcodesMap({});
    expect(map.equals(SuggestedBarcodesMap({})), isTrue);

    expect(map[OsmUID.parse('1:1')], isNull);

    map[OsmUID.parse('1:1')] = ['123'];

    expect(map[OsmUID.parse('1:1')], equals(['123']));
    expect(
        map.equals(SuggestedBarcodesMap({
          OsmUID.parse('1:1'): ['123']
        })),
        isTrue);
  });

  test('suggestions count', () {
    final map = SuggestedBarcodesMap({
      OsmUID.parse('1:1'): ['123'],
      OsmUID.parse('1:2'): ['567', '789'],
    });

    expect(map.suggestionsCountFor(OsmUID.parse('1:1')), equals(1));
    expect(map.suggestionsCountFor(OsmUID.parse('1:2')), equals(2));
  });

  test('add', () {
    final map = SuggestedBarcodesMap({
      OsmUID.parse('1:1'): ['123'],
    });
    expect(
        map.equals(SuggestedBarcodesMap({
          OsmUID.parse('1:1'): ['123']
        })),
        isTrue);

    map.add(OsmUID.parse('1:1'), ['234']);
    expect(
        map.equals(SuggestedBarcodesMap({
          OsmUID.parse('1:1'): ['123', '234']
        })),
        isTrue);

    // Let's add a duplicate
    map.add(OsmUID.parse('1:1'), ['234']);
    expect(
        map.equals(SuggestedBarcodesMap({
          OsmUID.parse('1:1'): ['123', '234']
        })),
        isTrue);
  });

  test('unmodifiable', () {
    var map = SuggestedBarcodesMap({
      OsmUID.parse('1:1'): ['123'],
    });
    map = map.unmodifiable();

    var caught = 0;
    try {
      map.add(OsmUID.parse('1:1'), ['345']);
    } catch (e) {
      caught += 1;
    }
    try {
      map[OsmUID.parse('1:2')] = ['567'];
    } catch (e) {
      caught += 1;
    }

    expect(caught, equals(2));
    expect(
        map.equals(SuggestedBarcodesMap({
          OsmUID.parse('1:1'): ['123']
        })),
        isTrue);
  });
}
