import 'package:plante/outside/off/off_cacher.dart';
import 'package:test/test.dart';

void main() {
  late OffCacher offCacher;

  setUp(() async {
    offCacher = OffCacher();
  });

  test('cached barcodes at shops: store, delete, reload', () async {
    await offCacher.dbForTesting;

    // Create
    var now = DateTime.now();
    // Erasing milliseconds
    now = DateTime(
        now.year, now.month, now.day, now.hour, now.minute, now.second);
    await offCacher.setBarcodes(now, 'ru', 'spar', ['123', '456']);
    await offCacher.setBarcodes(now, 'be', 'aldi', ['456', '789']);

    // Read
    var barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'spar');
    expect(barcodesAtShop, isNotNull);
    expect(barcodesAtShop!.shopId, equals('spar'));
    expect(barcodesAtShop.countryCode, equals('ru'));
    expect(barcodesAtShop.whenObtained, equals(now));
    expect(barcodesAtShop.barcodes.toSet(), equals({'123', '456'}));

    barcodesAtShop = await offCacher.getBarcodesAtShop('be', 'aldi');
    expect(barcodesAtShop!.shopId, equals('aldi'));
    expect(barcodesAtShop.countryCode, equals('be'));
    expect(barcodesAtShop.whenObtained, equals(now));
    expect(barcodesAtShop.barcodes.toSet(), equals({'456', '789'}));

    barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'aldi');
    expect(barcodesAtShop, isNull);

    // Delete
    barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'spar');
    expect(barcodesAtShop, isNotNull);
    await offCacher.deleteShopsCache(['spar'], 'ru');
    barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'spar');
    expect(barcodesAtShop, isNull);

    // Reload
    // Create a second cacher with same DB,
    final offCacher2 = OffCacher.withDb(await offCacher.dbForTesting);
    barcodesAtShop = await offCacher2.getBarcodesAtShop('be', 'aldi');
    expect(barcodesAtShop!.shopId, equals('aldi'));
    expect(barcodesAtShop.countryCode, equals('be'));
    expect(barcodesAtShop.whenObtained, equals(now));
    expect(barcodesAtShop.barcodes.toSet(), equals({'456', '789'}));
  });

  test('no cache VS empty cache', () async {
    // No cache yet
    var barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'spar');
    expect(barcodesAtShop, isNull);

    // Empty cache
    var now = DateTime.now();
    // Erasing milliseconds
    now = DateTime(
        now.year, now.month, now.day, now.hour, now.minute, now.second);
    await offCacher.setBarcodes(now, 'ru', 'spar', const []);
    barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'spar');
    expect(barcodesAtShop, isNotNull);
    expect(barcodesAtShop!.barcodes, isEmpty);
    expect(barcodesAtShop.whenObtained, equals(now));

    // No cache again
    await offCacher.deleteShopsCache(['spar'], 'ru');
    barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'spar');
    expect(barcodesAtShop, isNull);
  });

  test('cannot add a barcode, can only rewrite cache', () async {
    var now = DateTime.now();
    // Erasing milliseconds
    now = DateTime(
        now.year, now.month, now.day, now.hour, now.minute, now.second);
    await offCacher.setBarcodes(now, 'ru', 'spar', ['123', '456']);

    final now2 = now.add(const Duration(days: 10));
    await offCacher.setBarcodes(now2, 'ru', 'spar', ['567', '789']);

    final barcodesAtShop = await offCacher.getBarcodesAtShop('ru', 'spar');
    expect(barcodesAtShop!.shopId, equals('spar'));
    expect(barcodesAtShop.countryCode, equals('ru'));
    expect(barcodesAtShop.whenObtained, isNot(equals(now)));
    expect(barcodesAtShop.whenObtained, equals(now2));
    expect(barcodesAtShop.barcodes.toSet(), equals({'567', '789'}));
  });
}
