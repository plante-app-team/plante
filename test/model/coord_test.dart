import 'package:plante/model/coord.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  test('lat lon normalization', () async {
    final coord1 = Coord(lat: 100, lon: 181);
    expect(coord1, equals(Coord(lat: 90, lon: -179)));
    expect(coord1.lat, equals(90));
    expect(coord1.lon, equals(-179));

    final coord2 = Coord(lat: -100, lon: -181);
    expect(coord2, equals(Coord(lat: -90, lon: 179)));
    expect(coord2.lat, equals(-90));
    expect(coord2.lon, equals(179));
  });

  test('serialization-deserialization', () async {
    final coord = Coord(lat: 90, lon: -179);
    expect(Coord.fromJson(coord.toJson()), equals(coord));
  });

  test('low-precision fields', () async {
    final coord = Coord(lat: 1.23456, lon: 2.34567, precision: 3);
    expect(coord.lat, closeTo(1.234, 0.000000000001));
    expect(coord.lon, closeTo(2.345, 0.000000000001));
  });

  test('equals and hash code', () async {
    // We expect [equals] and [hash code] to depend on precision.
    final coord1 = Coord(lat: 1.23456, lon: 2.34567, precision: 3);
    final coord2 = Coord(lat: 1.23499, lon: 2.34599, precision: 3);
    expect(coord1, equals(coord2));
    expect(coord1.hashCode, equals(coord2.hashCode));
  });

  test('make Coord a square', () async {
    final coord = Coord(lat: 50, lon: 50);
    final square = coord.makeSquare(20);

    expect(square.north, closeTo(60, 0.00001));
    expect(square.east, closeTo(60, 0.00001));
    expect(square.south, closeTo(40, 0.00001));
    expect(square.west, closeTo(40, 0.00001));
  });

  test('make Coord a square close to 180 on the west', () async {
    final coord = Coord(lat: 50, lon: -175);
    final square = coord.makeSquare(20);

    expect(square.north, closeTo(60, 0.00001));
    expect(square.east, closeTo(-165, 0.00001));
    expect(square.south, closeTo(40, 0.00001));
    expect(square.west, closeTo(175, 0.00001));
  });

  test('make Coord a square close to 180 on the east', () async {
    final coord = Coord(lat: 50, lon: 175);
    final square = coord.makeSquare(20);

    expect(square.north, closeTo(60, 0.00001));
    expect(square.east, closeTo(-175, 0.00001));
    expect(square.south, closeTo(40, 0.00001));
    expect(square.west, closeTo(165, 0.00001));
  });
}
