import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/cached_operation.dart';
import 'package:plante/base/file_system_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';

enum OffShopsListObtainerError {
  NETWORK,
  OTHER,
}

class OffShopsListObtainer {
  static const _DEFAULT_FOLDER_NAME = 'off_shops_lists';
  static const _DEFAULT_MAX_FOLDER_SIZE = 1024 * 1024 * 50;
  static const _DEFAULT_MAX_PERSISTENT_CACHE_LIFETIME = Duration(days: 30);
  final String folderName;
  final int maxFolderSize;
  final Duration maxPersistentCacheLifetime;

  final OffApi _offApi;
  final _cache = <String, List<OffShop>>{};
  final _coolCache =
      <String, CachedOperation<List<OffShop>, OffShopsListObtainerError>>{};

  OffShopsListObtainer(
    this._offApi, {
    this.folderName = _DEFAULT_FOLDER_NAME,
    this.maxFolderSize = _DEFAULT_MAX_FOLDER_SIZE,
    this.maxPersistentCacheLifetime = _DEFAULT_MAX_PERSISTENT_CACHE_LIFETIME,
  });

  Future<Result<List<OffShop>, OffShopsListObtainerError>> getShopsForCountry(
      String countryIso) async {
    if (_coolCache[countryIso] == null) {
      _coolCache[countryIso] =
          CachedOperation(() => _getShopsForCountryImpl(countryIso));
    }
    return _coolCache[countryIso]!.result;
  }

  Future<Result<List<OffShop>, OffShopsListObtainerError>>
      _getShopsForCountryImpl(String countryIso) async {
    final cachedShops = _cache[countryIso];
    if (cachedShops != null) {
      return Ok(cachedShops);
    }

    final file = await _getFileFor(countryIso);
    String? jsonText;
    if (await file.exists() == false) {
      final jsonTextRes = await _offApi.getShopsJsonForCountry(countryIso);
      if (jsonTextRes.isErr) {
        return Err(jsonTextRes.unwrapErr().convert());
      }
      final tmpFile = await _createTmpFile();
      jsonText = jsonTextRes.unwrap();
      await tmpFile.writeAsString(jsonText);
      await tmpFile.rename(file.absolute.path);
      final fileSize = await file.length();
      Log.i('Downloaded OFF shops for $countryIso, size: $fileSize');

      await maybeCleanUpOldestFiles(
          dir: await getFolder(),
          maxDirSizeBytes: maxFolderSize,
          maxFileAgeMillis: maxPersistentCacheLifetime.inMilliseconds);
      if (await file.exists() == false) {
        Log.e('OFF shops file for "$countryIso" was cleaned up '
            'immediately after it was downloaded - is it too large?');
        return Err(OffShopsListObtainerError.OTHER);
      }
    } else {
      Log.i('Found OFF shops for "$countryIso", in cache');
    }

    jsonText ??= await file.readAsString();

    final Map shops = {'json': jsonText, 'countryIso': countryIso};
    final result = await compute(_parseShops, shops);
    if (result != null) {
      _cache[countryIso] = result;
      return Ok(result);
    } else {
      Log.w('OffShopsListObtainer: invalid JSON: $jsonText');
      await file.delete();
      return Err(OffShopsListObtainerError.OTHER);
    }
  }

  static List<OffShop>? _parseShops(Map shops) {
    final resultJson = jsonDecodeSafe(shops['json'] as String);
    if (resultJson == null) {
      return null;
    }
    final shopsJson = resultJson['tags'] as List<dynamic>;
    return shopsJson
        .map((shop) => OffShop.fromJson(shop, shops['countryIso'] as String))
        .whereType<OffShop>()
        .toList();
  }

  Future<File> _getFileFor(String countryIso) async {
    final folder = await getFolder();
    return File('${folder.absolute.path}/$countryIso.json');
  }

  Future<Directory> getFolder() async {
    final internalStorage = await getAppDir();
    var result = Directory('${internalStorage.path}/$folderName');

    if (await result.exists() == false) {
      result = await result.create(recursive: true);
    }
    return result;
  }

  Future<File> _createTmpFile() async {
    final folder = await getFolder();
    final rand = randInt(1, 99999);
    final now = DateTime.now();
    return File('${folder.absolute.path}/$rand.$now.tmp');
  }
}

extension _OffRestApiErrorExt on OffRestApiError {
  OffShopsListObtainerError convert() {
    switch (this) {
      case OffRestApiError.NETWORK:
        return OffShopsListObtainerError.NETWORK;
      case OffRestApiError.OTHER:
        return OffShopsListObtainerError.OTHER;
    }
  }
}
