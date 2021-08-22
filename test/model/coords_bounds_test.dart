import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  test('contains coord', () async {
    final bounds1 = CoordsBounds(
      southwest: Coord(lat: 10, lon: 10),
      northeast: Coord(lat: 20, lon: 20),
    );
    expect(bounds1.contains(Coord(lat: 15, lon: 15)), isTrue);
    expect(bounds1.contains(Coord(lat: 9, lon: 15)), isFalse);
    expect(bounds1.contains(Coord(lat: 21, lon: 15)), isFalse);
    expect(bounds1.contains(Coord(lat: 15, lon: 9)), isFalse);
    expect(bounds1.contains(Coord(lat: 15, lon: 21)), isFalse);

    final bounds2 = CoordsBounds(
      southwest: Coord(lat: 10, lon: 20),
      northeast: Coord(lat: 20, lon: 10),
    );
    expect(bounds2.contains(Coord(lat: 15, lon: 15)), isFalse);
    expect(bounds2.contains(Coord(lat: 15, lon: 9)), isTrue);
    expect(bounds2.contains(Coord(lat: 15, lon: 21)), isTrue);
    expect(bounds1.contains(Coord(lat: 9, lon: 9)), isFalse);
    expect(bounds1.contains(Coord(lat: 21, lon: 9)), isFalse);
  });

  test('serialize deserialize', () async {
    final bounds = CoordsBounds(
      southwest: Coord(lat: 10, lon: 10),
      northeast: Coord(lat: 20, lon: 20),
    );
    expect(CoordsBounds.fromJson(bounds.toJson()), equals(bounds));
  });

  test('equals, hash codes and precision', () async {
    final bounds1 = CoordsBounds(
      southwest: Coord(lat: 1.23456, lon: 1.34567, precision: 3),
      northeast: Coord(lat: 2.23456, lon: 2.34567, precision: 3),
    );
    final bounds2 = CoordsBounds(
      southwest: Coord(lat: 1.23499, lon: 1.34599, precision: 3),
      northeast: Coord(lat: 2.23499, lon: 2.34599, precision: 3),
    );

    // We expect [equals] and [hash code] to depend on precision.
    expect(bounds1, equals(bounds2));
    expect(bounds1.hashCode, equals(bounds2.hashCode));
  });

  void containsBoundsTestImpl(
      {required Coord southwest1,
      required Coord northeast1,
      required double diff}) {
    final southwest2 =
        Coord(lat: southwest1.lat + diff, lon: southwest1.lon + diff);
    final northeast2 =
        Coord(lat: northeast1.lat - diff, lon: northeast1.lon - diff);

    final bounds1 = CoordsBounds(southwest: southwest1, northeast: northeast1);
    var bounds2 = CoordsBounds(southwest: southwest2, northeast: northeast2);
    expect(bounds1.containsBounds(bounds2), isTrue);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = CoordsBounds(
        southwest: northeast2,
        northeast:
            Coord(lat: northeast1.lat + diff, lon: northeast1.lon - diff));
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = CoordsBounds(
        southwest:
            Coord(lat: southwest1.lat - diff, lon: southwest1.lon + diff),
        northeast: northeast2);
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = CoordsBounds(
        southwest: northeast2,
        northeast:
            Coord(lat: northeast1.lat - diff, lon: northeast1.lon + diff));
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = CoordsBounds(
        southwest:
            Coord(lat: southwest1.lat + diff, lon: southwest1.lon - diff),
        northeast: northeast2);
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);
  }

  test('bounds1 (not) contains bounds2', () async {
    containsBoundsTestImpl(
        southwest1: Coord(lat: 10, lon: 10),
        northeast1: Coord(lat: 20, lon: 20),
        diff: 3);
  });

  test('fiji: bounds1 contains bounds2 when longitude1 overflows', () async {
    containsBoundsTestImpl(
        southwest1: Coord(lat: 10, lon: 175),
        northeast1: Coord(lat: 50, lon: -145),
        diff: 10);
  });

  test('fiji: bounds1 contains bounds2 when both longitudes overflows',
      () async {
    containsBoundsTestImpl(
        southwest1: Coord(lat: 10, lon: 175),
        northeast1: Coord(lat: 30, lon: -145),
        diff: 3);
  });

  test('england: bounds1 contains bounds2 when longitude1 overflows', () async {
    containsBoundsTestImpl(
        southwest1: Coord(lat: 10, lon: -5),
        northeast1: Coord(lat: 50, lon: 35),
        diff: 10);
  });

  test('england: bounds1 contains bounds2 when both longitudes overflows',
      () async {
    containsBoundsTestImpl(
        southwest1: Coord(lat: 10, lon: -5),
        northeast1: Coord(lat: 30, lon: 35),
        diff: 3);
  });
}
