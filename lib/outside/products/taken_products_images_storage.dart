import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';

/// Persistent storage of taken images which are uploaded.
///
/// The storage is needed because OFF will return errors on images uploadings
/// when an image was already uploaded before. But such errors cannot be
/// reliably parsed by our code since they look like this:
///   {status: status not ok, status_verbose: null, error: Эта картинка уже была загружена, imgid: 3}
/// ...the error has no status code and its error messages is localized for
/// some reason.
///
/// We have no reliable way to avoid this errors if we don't have a persistent
/// storage of some sort, which would track which images were uploaded and
/// which were not.
/// The persistence is needed because when our app is minimized (or a camera app
/// is opened to take a picture of a product), the app might get killed by the
/// OS. When app reopens, we restore the before-killed state and might need to
/// know then whether some picture of a product was already uploaded before the
/// app was killed.
class TakenProductsImagesStorage {
  static const MAX_SIZE = 20;
  static const _FILE_NAME = 'taken_products_images_storage.json';

  final String fileName;
  var _loaded = false;
  final _loadedCompleter = Completer<void>();
  final _delayedActions = <dynamic Function()>[];
  final _images = <Uri>[];

  bool get loaded => _loaded;
  Future<void> get loadedFuture => _loadedCompleter.future;

  @visibleForTesting
  final Future<void>? initDelayForTesting;

  TakenProductsImagesStorage(
      {this.fileName = _FILE_NAME, this.initDelayForTesting}) {
    if (initDelayForTesting != null && !isInTests()) {
      throw Exception(
          'TakenProductsImagesTable.initDelayForTesting is not in tests');
    }
    _asyncInit();
  }

  void _asyncInit() async {
    if (initDelayForTesting != null) {
      await initDelayForTesting;
    }

    final file = await _getStorageFile();
    if (!(await file.exists())) {
      await _onInited();
      return;
    }

    try {
      final imagesDynamic =
          jsonDecode(await file.readAsString()) as List<dynamic>;
      final cache = imagesDynamic
          .map((e) => Uri.tryParse(e as String))
          .where((e) => e != null)
          .map((e) => e!);
      _images.addAll(cache);
    } catch (e) {
      Log.w('Error while reading taken products images cache', ex: e);
      await file.delete();
    }

    await _onInited();
  }

  Future<void> _onInited() async {
    _loaded = true;
    for (final action in _delayedActions) {
      await action.call();
    }
    _delayedActions.clear();
    _loadedCompleter.complete();
  }

  Future<File> _getStorageFile() async {
    final internalStorage = await getAppDir();
    return File('${internalStorage.path}/$fileName');
  }

  Future<void> store(Uri localFile) async {
    if (!localFile.isScheme('FILE')) {
      Log.e('localFile is not a file! localFile: $localFile');
      return;
    }
    return _executeOrDelay(() => _storeImpl(localFile));
  }

  Future<T> _executeOrDelay<T>(Future<T> Function() action) async {
    final completer = Completer<T>();
    final actionWrapper = () async {
      final result = await action.call();
      completer.complete(result);
    };
    if (_loaded) {
      await actionWrapper.call();
    } else {
      _delayedActions.add(actionWrapper);
    }
    return completer.future;
  }

  Future<void> _storeImpl(Uri localFile) async {
    _images.add(localFile);
    if (MAX_SIZE < _images.length) {
      _images.removeAt(0);
    }
    final json = jsonEncode(_images.map((e) => e.toString()).toList());

    final file = await _getStorageFile();
    await file.writeAsString(json, flush: true);
  }

  Future<bool> contains(Uri localFile) async {
    return _executeOrDelay(() async => _containsImpl(localFile));
  }

  bool _containsImpl(Uri localFile) {
    return _images.contains(localFile);
  }

  @visibleForTesting
  Future<void> clearForTesting() {
    if (!isInTests()) {
      throw Exception('TakenProductsImagesStorage.clearForTesting wrong call');
    }
    return _executeOrDelay(() async {
      final file = await _getStorageFile();
      if (await file.exists()) {
        await file.delete(recursive: true);
      }
    });
  }
}
