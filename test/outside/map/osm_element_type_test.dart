import 'package:plante/outside/map/osm_element_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {});

  test('concrete persistent codes values', () {
    // If new elements added, test must be changed
    expect(OsmElementType.values.length, equals(3));

    // Same persistent values are also used in the backend -
    // it's prohibited to change the values.
    expect(OsmElementType.NODE.persistentCode, equals(1));
    expect(OsmElementType.RELATION.persistentCode, equals(2));
    expect(OsmElementType.WAY.persistentCode, equals(3));
  });

  test('concrete names values', () {
    // If new elements added, test must be changed
    expect(OsmElementType.values.length, equals(3));

    // Same names are also used in Open Street Map -
    // it's prohibited to change the values.
    expect(OsmElementType.NODE.name, equals('node'));
    expect(OsmElementType.RELATION.name, equals('relation'));
    expect(OsmElementType.WAY.name, equals('way'));
  });

  test('values can be obtained from their persistent codes', () {
    for (final type in OsmElementType.values) {
      expect(type, equals(osmElementTypeFromCode(type.persistentCode)));
    }
  });

  test('all values can be obtained from their str vals', () {
    // If new elements added, test must be changed
    expect(OsmElementType.values.length, equals(3));

    expect(OsmElementType.NODE, equals(osmElementTypeFromStr('node')));
    expect(OsmElementType.RELATION, equals(osmElementTypeFromStr('relation')));
    expect(OsmElementType.WAY, equals(osmElementTypeFromStr('way')));
  });
}
