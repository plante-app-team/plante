import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/products/suggestions/suggested_barcodes_map.dart';
import 'package:plante/products/suggestions/suggested_barcodes_map_full.dart';
import 'package:plante/products/suggestions/suggestion_type.dart';
import 'package:plante/products/suggestions/suggestions_for_shop.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  test('equals', () {
    final map1 = SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['123'],
      }),
      SuggestionType.OFF: SuggestedBarcodesMap({
        OsmUID.parse('1:3'): ['345'],
      }),
    });
    final map2 = SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['123'],
      }),
      SuggestionType.OFF: SuggestedBarcodesMap({
        OsmUID.parse('1:3'): ['345'],
      }),
    });
    expect(map1.equals(map2), isTrue);

    map2[SuggestionType.OFF] = SuggestedBarcodesMap({
      OsmUID.parse('1:3'): ['567'],
    });
    expect(map1.equals(map2), isFalse);

    final map3 = SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['123'],
      }),
      SuggestionType.OFF: SuggestedBarcodesMap({
        OsmUID.parse('1:3'): ['345'],
      }),
    });
    expect(map1.equals(map3), isTrue);

    map3.add(
        SuggestionsForShop(OsmUID.parse('1:3'), SuggestionType.OFF, ['777']));
    expect(map1.equals(map3), isFalse);
  });

  test('operator []', () {
    final map = SuggestedBarcodesMapFull({});

    expect(map[SuggestionType.RADIUS], isNull);

    map[SuggestionType.RADIUS] = SuggestedBarcodesMap({
      OsmUID.parse('1:3'): ['345'],
    });

    expect(
        map[SuggestionType.RADIUS]!.equals(SuggestedBarcodesMap({
          OsmUID.parse('1:3'): ['345'],
        })),
        isTrue);
    expect(
        map.equals(SuggestedBarcodesMapFull({
          SuggestionType.RADIUS: SuggestedBarcodesMap({
            OsmUID.parse('1:3'): ['345'],
          }),
        })),
        isTrue);
  });

  test('suggestions count', () {
    final map = SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['123'],
      }),
      SuggestionType.OFF: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['345'],
        OsmUID.parse('1:3'): ['345'],
      }),
    });

    expect(map.suggestionsCountFor(OsmUID.parse('1:3')), equals(1));
    expect(map.suggestionsCountFor(OsmUID.parse('1:1')), equals(2));
  });

  test('suggestions count with specified type', () {
    final map = SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['123'],
      }),
      SuggestionType.OFF: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['345'],
        OsmUID.parse('1:3'): ['345'],
      }),
    });

    expect(map.suggestionsCountFor(OsmUID.parse('1:3'), SuggestionType.OFF),
        equals(1));
    expect(map.suggestionsCountFor(OsmUID.parse('1:3'), SuggestionType.RADIUS),
        equals(0));
    expect(map.suggestionsCountFor(OsmUID.parse('1:1'), SuggestionType.OFF),
        equals(1));
    expect(map.suggestionsCountFor(OsmUID.parse('1:1'), SuggestionType.RADIUS),
        equals(1));
    expect(map.suggestionsCountFor(OsmUID.parse('1:1')), equals(2));
  });

  test('add', () {
    final map = SuggestedBarcodesMapFull({});

    expect(map.equals(SuggestedBarcodesMapFull({})), isTrue);

    map.add(
        SuggestionsForShop(OsmUID.parse('1:1'), SuggestionType.OFF, ['123']));
    map.add(
        SuggestionsForShop(OsmUID.parse('1:1'), SuggestionType.OFF, ['345']));

    expect(
        map.equals(SuggestedBarcodesMapFull({
          SuggestionType.OFF: SuggestedBarcodesMap({
            OsmUID.parse('1:1'): ['123', '345'],
          }),
        })),
        isTrue);
  });

  test('unmodifiable', () {
    var map = SuggestedBarcodesMapFull({
      SuggestionType.RADIUS: SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['123'],
      }),
    });
    map = map.unmodifiable();

    var caught = 0;
    try {
      map.add(
          SuggestionsForShop(OsmUID.parse('1:1'), SuggestionType.OFF, ['123']));
    } catch (e) {
      caught += 1;
    }
    try {
      map[SuggestionType.OFF] = SuggestedBarcodesMap({
        OsmUID.parse('1:1'): ['123'],
      });
    } catch (e) {
      caught += 1;
    }

    expect(caught, equals(2));
    expect(
        map.equals(SuggestedBarcodesMapFull({
          SuggestionType.RADIUS: SuggestedBarcodesMap({
            OsmUID.parse('1:1'): ['123'],
          }),
        })),
        isTrue);
  });
}
