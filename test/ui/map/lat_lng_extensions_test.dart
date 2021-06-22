import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test/test.dart';
import 'package:plante/ui/map/lat_lng_extensions.dart';


void main() {
  setUp(() {});

  void testImpl({
    required LatLng southwest1,
      required LatLng northeast1,
      required double diff}) {
    final southwest2 = LatLng(
        southwest1.latitude + diff,
        southwest1.longitude + diff);
    final northeast2 = LatLng(
        northeast1.latitude - diff,
        northeast1.longitude - diff);

    final bounds1 = LatLngBounds(
        southwest: southwest1,
        northeast: northeast1);
    var bounds2 = LatLngBounds(
        southwest: southwest2,
        northeast: northeast2);
    expect(bounds1.containsBounds(bounds2), isTrue);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = LatLngBounds(
        southwest: northeast2,
        northeast: LatLng(
            northeast1.latitude + diff,
            northeast1.longitude - diff));
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = LatLngBounds(
        southwest: LatLng(
            southwest1.latitude - diff,
            southwest1.longitude + diff),
        northeast: northeast2);
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = LatLngBounds(
        southwest: northeast2,
        northeast: LatLng(
            northeast1.latitude - diff,
            northeast1.longitude + diff));
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);

    bounds2 = LatLngBounds(
        southwest: LatLng(
            southwest1.latitude + diff,
            southwest1.longitude - diff),
        northeast: northeast2);
    expect(bounds1.containsBounds(bounds2), isFalse);
    expect(bounds2.containsBounds(bounds1), isFalse);
  }

  test('bounds1 (not) contains bounds2', () async {
    testImpl(
      southwest1: const LatLng(10, 10),
      northeast1: const LatLng(20, 20),
      diff: 3);
  });

  test('fiji: bounds1 contains bounds2 when longitude1 overflows', () async {
    testImpl(
        southwest1: const LatLng(10, 175),
        northeast1: const LatLng(50, -145),
        diff: 10);
  });

  test('fiji: bounds1 contains bounds2 when both longitudes overflows', () async {
    testImpl(
        southwest1: const LatLng(10, 175),
        northeast1: const LatLng(30, -145),
        diff: 3);
  });

  test('england: bounds1 contains bounds2 when longitude1 overflows', () async {
    testImpl(
        southwest1: const LatLng(10, -5),
        northeast1: const LatLng(50, 35),
        diff: 10);
  });
  test('england: bounds1 contains bounds2 when both longitudes overflows', () async {
    testImpl(
        southwest1: const LatLng(10, -5),
        northeast1: const LatLng(30, 35),
        diff: 3);
  });

  test('make LatLng a square', () async {
    const latLng = LatLng(50, 50);
    final square = latLng.makeSquare(20);

    expect(square.north, closeTo(60, 0.00001));
    expect(square.east, closeTo(60, 0.00001));
    expect(square.south, closeTo(40, 0.00001));
    expect(square.west, closeTo(40, 0.00001));
  });

  test('make LatLng a square close to 180 on the west', () async {
    const latLng = LatLng(50, -175);
    final square = latLng.makeSquare(20);

    expect(square.north, closeTo(60, 0.00001));
    expect(square.east, closeTo(-165, 0.00001));
    expect(square.south, closeTo(40, 0.00001));
    expect(square.west, closeTo(175, 0.00001));
  });

  test('make LatLng a square close to 180 on the east', () async {
    const latLng = LatLng(50, 175);
    final square = latLng.makeSquare(20);

    expect(square.north, closeTo(60, 0.00001));
    expect(square.east, closeTo(-175, 0.00001));
    expect(square.south, closeTo(40, 0.00001));
    expect(square.west, closeTo(165, 0.00001));
  });
}
