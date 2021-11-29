import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_obtainer.dart';

import '../../common_mocks.mocks.dart';

void main() {
  late MockOffApi offApi;
  late OffShopsListObtainer offShopsListObtainer;

  const validResponseJson = '''
    {
      "count":2,
      "tags":[
        {
          "id":"delhaize",
          "known":0,
          "name":"Delhaize",
          "products":10342,
          "url":"https://be.openfoodfacts.org/winkel/delhaize"
        },
        {
          "id":"colruyt",
          "known":0,
          "name":"Colruyt",
          "products":3410,
          "url":"https://be.openfoodfacts.org/winkel/colruyt"
        }
      ]
    }
    ''';

  setUp(() async {
    offApi = MockOffApi();

    when(offApi.getShopsJsonForCountry(any))
        .thenAnswer((_) async => Ok(validResponseJson));

    final rand = randInt(1, 99999);
    final now = DateTime.now();
    final folderName = 'off_shops_list_obtainer_test.$rand.$now';
    offShopsListObtainer = OffShopsListObtainer(offApi, folderName: folderName);
  });

  test('normal scenario', () async {
    final shopsRes = await offShopsListObtainer.getShopsForCountry('ru');
    final shops = shopsRes.unwrap();
    final expectedShops = [
      OffShop((e) => e
        ..id = 'delhaize'
        ..name = 'Delhaize'
        ..productsCount = 10342
        ..country = 'ru'),
      OffShop((e) => e
        ..id = 'colruyt'
        ..name = 'Colruyt'
        ..productsCount = 3410
        ..country = 'ru'),
    ];
    expect(shops, equals(expectedShops));
  });

  test('2 consequent calls for same country causes 1 load', () async {
    verifyNever(offApi.getShopsJsonForCountry(any));

    final shopsRes1 = await offShopsListObtainer.getShopsForCountry('ru');
    final shopsRes2 = await offShopsListObtainer.getShopsForCountry('ru');

    // Second 'getShopsForCountry' call is expected to not touch OFF api,
    // it's expected to use cached value
    verify(offApi.getShopsJsonForCountry(any)).called(1);

    expect(shopsRes1.unwrap(), equals(shopsRes2.unwrap()));
  });

  test('2 immediate calls for same country causes 1 load', () async {
    verifyNever(offApi.getShopsJsonForCountry(any));

    final shopsResFuture1 = offShopsListObtainer.getShopsForCountry('ru');
    final shopsResFuture2 = offShopsListObtainer.getShopsForCountry('ru');

    final shopsRes1 = await shopsResFuture1;
    final shopsRes2 = await shopsResFuture2;

    // Even though we didn't wait for the first 'getShopsForCountry'
    // call to finish we still expect the second call to not touch the OFF api.
    // We expect the obtainer to protect itself from immediate consequent calls,
    // to wait for first call result and return it from the second call.
    verify(offApi.getShopsJsonForCountry(any)).called(1);

    expect(shopsRes1.unwrap(), equals(shopsRes2.unwrap()));
  });

  test('fail then success', () async {
    when(offApi.getShopsJsonForCountry(any)).thenAnswer(
        (_) async => Ok('${validResponseJson}AAAAAAAAAA now it is invalid!'));
    verifyNever(offApi.getShopsJsonForCountry(any));

    final shopsRes1 = await offShopsListObtainer.getShopsForCountry('ru');
    expect(shopsRes1.isErr, isTrue);

    when(offApi.getShopsJsonForCountry(any))
        .thenAnswer((_) async => Ok(validResponseJson));
    final shopsRes2 = await offShopsListObtainer.getShopsForCountry('ru');
    final shops2 = shopsRes2.unwrap();

    // Second 'getShopsForCountry' call is expected to touch OFF api,
    // because first call returned invalid JSON
    verify(offApi.getShopsJsonForCountry(any)).called(2);

    expect(shops2.length, equals(2));
  });

  test('FS cache is reused by a second instance', () async {
    final shopsRes1 = await offShopsListObtainer.getShopsForCountry('ru');
    expect(shopsRes1.isOk, isTrue);
    verify(offApi.getShopsJsonForCountry(any)).called(1);

    final offShopsListObtainer2 = OffShopsListObtainer(offApi,
        folderName: offShopsListObtainer.folderName);
    final shopsRes2 = await offShopsListObtainer2.getShopsForCountry('ru');

    // Second 'getShopsForCountry' call is expected to not touch OFF api,
    // it's expected to use FS cached value
    verifyNever(offApi.getShopsJsonForCountry(any));

    expect(shopsRes2.unwrap(), equals(shopsRes1.unwrap()));
  });

  test('local cache is used instead of FS cache while instantiated', () async {
    verifyNever(offApi.getShopsJsonForCountry(any));

    final shopsRes1 = await offShopsListObtainer.getShopsForCountry('ru');
    verify(offApi.getShopsJsonForCountry(any)).called(1);

    await (await offShopsListObtainer.getFolder()).delete(recursive: true);

    final shopsRes2 = await offShopsListObtainer.getShopsForCountry('ru');
    expect(shopsRes1.unwrap(), equals(shopsRes2.unwrap()));

    // Second 'getShopsForCountry' call is expected to not touch OFF api,
    // even though we deleted its folder with persistent cache. It's expected
    // to have its cache in a field and to use that field.
    verifyNever(offApi.getShopsJsonForCountry(any));

    // Now we'll try to use the FS cache
    final offShopsListObtainer2 = OffShopsListObtainer(offApi,
        folderName: offShopsListObtainer.folderName);
    final shopsRes3 = await offShopsListObtainer2.getShopsForCountry('ru');

    // A second call to the OFF api is expected, because there's no FS cache.
    verify(offApi.getShopsJsonForCountry(any)).called(1);

    expect(shopsRes2.unwrap(), equals(shopsRes3.unwrap()));
  });

  test('invalid JSON cached in FS causes cache invalidation', () async {
    verifyNever(offApi.getShopsJsonForCountry(any));

    final shopsRes1 = await offShopsListObtainer.getShopsForCountry('ru');
    expect(shopsRes1.isOk, isTrue);
    verify(offApi.getShopsJsonForCountry(any)).called(1);

    // Now let's mess with the FS cache!
    final files = (await offShopsListObtainer.getFolder()).listSync();
    for (final file in files) {
      (file as File)
          .writeAsStringSync('Now it is invalid!', mode: FileMode.append);
    }

    // Now we'll try to use the invalid FS cache
    final offShopsListObtainer2 = OffShopsListObtainer(offApi,
        folderName: offShopsListObtainer.folderName);
    final shopsRes2 = await offShopsListObtainer2.getShopsForCountry('ru');
    expect(shopsRes2.isErr, isTrue);

    // Second call to 'offShopsListObtainer2' is expected to be successful,
    // because the obtainer is expected to download the JSON again.
    final shopsRes3 = await offShopsListObtainer2.getShopsForCountry('ru');
    expect(shopsRes3.isOk, isTrue);

    expect(shopsRes1.unwrap(), equals(shopsRes3.unwrap()));
  });

  test('old files are being deleted', () async {
    offShopsListObtainer = OffShopsListObtainer(offApi,
        folderName: offShopsListObtainer.folderName,
        maxPersistentCacheLifetime: const Duration(seconds: 5));
    final folder = await offShopsListObtainer.getFolder();

    // Forcing 2 cache files to be created
    await offShopsListObtainer.getShopsForCountry('ru');
    await Future.delayed(const Duration(seconds: 3));
    await offShopsListObtainer.getShopsForCountry('be');

    // Both files expected to exist
    var files = folder.listSync();
    var filesNames = files.map((e) => e.path.split('/').last);
    expect(filesNames.toSet(), equals({'ru.json', 'be.json'}));

    // Wait for more than maxPersistentCacheLifetime and
    // cause third file creation
    await Future.delayed(const Duration(seconds: 3));
    await offShopsListObtainer.getShopsForCountry('by');

    // Now we expect the oldest file to be deleted
    files = folder.listSync();
    filesNames = files.map((e) => e.path.split('/').last);
    expect(filesNames.toSet(), equals({'be.json', 'by.json'}));
  });

  test('files are being deleted when folder is too large', () async {
    offShopsListObtainer = OffShopsListObtainer(offApi,
        folderName: offShopsListObtainer.folderName,
        maxFolderSize: validResponseJson.length * 2);
    final folder = await offShopsListObtainer.getFolder();

    // Forcing 2 cache files to be created
    await offShopsListObtainer.getShopsForCountry('ru');
    await Future.delayed(const Duration(seconds: 1));
    await offShopsListObtainer.getShopsForCountry('be');

    // Both files expected to exist
    var files = folder.listSync();
    var filesNames = files.map((e) => e.path.split('/').last);
    expect(filesNames.toSet(), equals({'ru.json', 'be.json'}));

    // Third cached file
    await offShopsListObtainer.getShopsForCountry('by');

    // Now we expect the oldest file to be deleted, because
    // we've set up maxFolderSize = 200% of json response size,
    // and with third file the folder would be filled up to 300% of
    // the response size.
    files = folder.listSync();
    filesNames = files.map((e) => e.path.split('/').last);
    expect(filesNames.toSet(), equals({'be.json', 'by.json'}));
  });
}
