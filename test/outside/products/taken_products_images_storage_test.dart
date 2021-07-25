import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/outside/products/taken_products_images_storage.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {});

  test('save and obtain data', () async {
    const fileName = 'taken_products_images_table_test1';
    final table = TakenProductsImagesStorage(fileName: fileName);
    await table.loadedFuture;

    final file1 = Uri.file('/tmp/asd1.jpg');
    final file2 = Uri.file('/tmp/asd2.jpg');
    await table.store(file1);
    await table.store(file2);

    expect(await table.contains(file1), isTrue);
    expect(await table.contains(file2), isTrue);
  });

  test('save and obtain data persistently', () async {
    const fileName = 'taken_products_images_table_test2';
    final table1 = TakenProductsImagesStorage(fileName: fileName);
    await table1.loadedFuture;

    final file1 = Uri.file('/tmp/asd1.jpg');
    final file2 = Uri.file('/tmp/asd2.jpg');
    await table1.store(file1);
    await table1.store(file2);

    final table2 = TakenProductsImagesStorage(fileName: fileName);
    await table2.loadedFuture;
    expect(await table2.contains(file1), isTrue);
    expect(await table2.contains(file2), isTrue);
  });

  test('save data limit (both local and persistent)', () async {
    const fileName = 'taken_products_images_table_test3';
    final table1 = TakenProductsImagesStorage(fileName: fileName);
    await table1.loadedFuture;

    // Store
    for (var index = 0;
        index < TakenProductsImagesStorage.MAX_SIZE * 2;
        ++index) {
      final file = Uri.file('/tmp/asd$index.jpg');
      await table1.store(file);
    }

    // Retrieve both local and persistent data
    final table2 = TakenProductsImagesStorage(fileName: fileName);
    await table2.loadedFuture;
    for (var index = 0;
        index < TakenProductsImagesStorage.MAX_SIZE * 2;
        ++index) {
      final file = Uri.file('/tmp/asd$index.jpg');
      if (index < TakenProductsImagesStorage.MAX_SIZE) {
        // Expect the eldest entries to be erased
        expect(await table1.contains(file), isFalse);
        expect(await table2.contains(file), isFalse);
      } else {
        // Expect the newest entries to be present
        expect(await table1.contains(file), isTrue);
        expect(await table1.contains(file), isTrue);
      }
    }
  });

  test('save data while initial load is still in progress', () async {
    final initDelayCompleter = Completer<void>();

    const fileName = 'taken_products_images_table_test4';
    final table = TakenProductsImagesStorage(
        fileName: fileName, initDelayForTesting: initDelayCompleter.future);

    // Save
    final file1 = Uri.file('/tmp/asd1.jpg');
    final file2 = Uri.file('/tmp/asd2.jpg');
    unawaited(table.store(file1));
    unawaited(table.store(file2));
    await Future.delayed(const Duration(milliseconds: 100));

    // Ensure the data is not saved yet
    expect(table.loaded, isFalse);

    initDelayCompleter.complete();
    await table.loadedFuture;

    // Ensure the data is saved now
    expect(table.loaded, isTrue);
    expect(await table.contains(file1), isTrue);
    expect(await table.contains(file2), isTrue);
  });

  test('obtain data while initial load is still in progress', () async {
    const fileName = 'taken_products_images_table_test5';
    final table1 = TakenProductsImagesStorage(fileName: fileName);
    await table1.loadedFuture;

    // Save
    final file1 = Uri.file('/tmp/asd1.jpg');
    final file2 = Uri.file('/tmp/asd2.jpg');
    await table1.store(file1);
    await table1.store(file2);

    final initDelayCompleter = Completer<void>();
    final table2 = TakenProductsImagesStorage(
        fileName: fileName, initDelayForTesting: initDelayCompleter.future);

    // Ensure the data is not loaded yet
    expect(table2.loaded, isFalse);
    final result1 = table2.contains(file1);
    final result2 = table2.contains(file2);

    initDelayCompleter.complete();
    await table2.loadedFuture;

    // Ensure the data is loaded now
    expect(table2.loaded, isTrue);
    expect(await result1, isTrue);
    expect(await result2, isTrue);
  });
}
