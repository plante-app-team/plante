import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';

/// A very simple storage which just stores in a file all
/// products given to it.
/// It doesn't check that the products are the same on the server so its
/// data may become outdated.
class ViewedProductsStorage {
  static const STORED_PRODUCTS_MAX = 20;
  static const _DEFAULT_FILE_NAME = 'viewed_products_storage.json';
  final bool loadPersistentProducts;
  final bool storePersistentProducts;
  final String storageFileName;
  final _cache = <Product>[];

  final _updatesStream = StreamController<void>.broadcast();

  ViewedProductsStorage(
      {this.loadPersistentProducts = true,
      this.storePersistentProducts = true,
      this.storageFileName = _DEFAULT_FILE_NAME}) {
    if (loadPersistentProducts) {
      _loadPersistentProducts();
    }
  }

  Stream<void> updates() => _updatesStream.stream;

  Future<void> loadPersistentProductsForTesting() async {
    if (!isInTests()) {
      throw Exception('Need to call from tests only');
    }
    await _loadPersistentProducts();
  }

  Future<void> _loadPersistentProducts() async {
    final file = await _getStorageFile();
    if (!(await file.exists())) {
      return;
    }

    var loaded = false;
    try {
      final cacheDynamic =
          jsonDecode(await file.readAsString()) as List<dynamic>;
      final cache = cacheDynamic
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .where((element) => element != null)
          .map((e) => e!);
      _cache.addAll(cache);
      loaded = true;
    } catch (e) {
      Log.w('Error while reading products cache', ex: e);
    }
    if (loaded) {
      _updatesStream.add(null);
    } else {
      await file.delete();
    }
  }

  Future<File> _getStorageFile() async {
    final internalStorage = await getAppDir();
    return File('${internalStorage.path}/$storageFileName');
  }

  List<Product> getProducts() {
    return _cache.toList(growable: false);
  }

  Future<void> addProduct(Product product) async {
    _cache.removeWhere((element) => element.barcode == product.barcode);
    _cache.add(product);
    if (_cache.length > STORED_PRODUCTS_MAX) {
      _cache.removeAt(0);
    }
    _updatesStream.add(null);
    await _storeProductsPersistently();
  }

  Future<void> _storeProductsPersistently() async {
    if (!storePersistentProducts) {
      return;
    }
    final file = await _getStorageFile();
    await file.writeAsString(jsonEncode(_cache), flush: true);
  }

  Future<void> purgeForTesting() async {
    final file = await _getStorageFile();
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException catch (e) {
        Log.w('Could not delete existing file ${file.absolute}', ex: e);
      }
    }
  }

  Future<void> dispose() async {
    await _updatesStream.close();
  }
}
