import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';

/// Stores in a file all products given to it.
///
/// The class has [storedProductsMax] - when a product is added and the overall
/// length start to exceed the max, products from the head are removed.
///
/// When a duplicate product (same barcode as an existing product) is added,
/// the old product is being removed, the new product is appended to the tail.
///
/// NOTE: the class doesn't check that the products are the same on any
/// backends, so its data may become outdated.
abstract class ProductsGroupPersistentStorageBase {
  final int storedProductsMax;
  final bool beingTested;
  final String storageFileName;
  final _cache = <Product>[];

  final _inited = Completer<void>();

  final _updatesStream = StreamController<void>.broadcast();

  Future<void> get inited => _inited.future;

  ProductsGroupPersistentStorageBase(
      {this.beingTested = false,
      required this.storageFileName,
      required this.storedProductsMax}) {
    if (!isInTests() || beingTested) {
      _loadPersistentProducts();
    } else {
      _inited.complete();
    }
  }

  Stream<void> updates() => _updatesStream.stream;

  Future<void> _loadPersistentProducts() async {
    try {
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
    } finally {
      _inited.complete();
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
    final newCache = [
      ..._cache,
      product,
    ];
    await setProducts(newCache);
  }

  Future<void> setProducts(Iterable<Product> products) async {
    _cache.clear();
    _cache.addAll(products);

    // Remove products duplicates
    final barcodes = <String>{};
    for (var index = _cache.length - 1; 0 <= index; --index) {
      if (barcodes.contains(_cache[index].barcode)) {
        _cache.removeAt(index);
      } else {
        barcodes.add(_cache[index].barcode);
      }
    }

    // Remove extra products
    while (_cache.length > storedProductsMax) {
      _cache.removeAt(0);
    }
    _updatesStream.add(null);
    await _storeProductsPersistently();
  }

  Future<void> _storeProductsPersistently() async {
    if (!isInTests() || beingTested) {
      final file = await _getStorageFile();
      await file.writeAsString(jsonEncode(_cache), flush: true);
    }
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
