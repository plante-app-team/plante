import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';

/// A very simple storage which just stores in a file all
/// products given to it.
/// It doesn't check that the products are the same on the server so its
/// data may become outdated.
class ViewedProductsStorage {
  static const STORED_PRODUCTS_MAX = 20;
  static const _FILE_NAME = 'viewed_products_storage.json';
  final _cache = <Product>[];

  final _updatesStream = StreamController<void>.broadcast();

  ViewedProductsStorage({bool loadPersistentProducts = true}) {
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
    final internalStorage = await getApplicationDocumentsDirectory();
    return File('${internalStorage.path}/$_FILE_NAME');
  }

  List<Product> getProducts() {
    return _cache.toList(growable: false);
  }

  void addProduct(Product product) {
    _cache.removeWhere((element) => element.barcode == product.barcode);
    _cache.add(product);
    if (_cache.length > STORED_PRODUCTS_MAX) {
      _cache.removeAt(0);
    }
    _updatesStream.add(null);
    _storeProductsPersistently();
  }

  Future<void> _storeProductsPersistently() async {
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

  void dispose() {
    _updatesStream.close();
  }
}
