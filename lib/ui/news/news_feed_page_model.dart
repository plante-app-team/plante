import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/news/news_feed_manager.dart';
import 'package:plante/outside/backend/news/news_piece.dart';
import 'package:plante/outside/backend/news/news_piece_product_at_shop.dart';
import 'package:plante/outside/backend/news/news_piece_type.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/ui_value.dart';

class NewsFeedPageModel {
  final NewsFeedManager _newsFeedManager;
  final ProductsObtainer _productsObtainer;
  final ShopsManager _shopsManager;

  final UIValuesFactory _uiValuesFactory;

  late final _loading = _uiValuesFactory.create(false);
  late final _lastError = _uiValuesFactory.create<GeneralError?>(null);
  late final _newsPieces = _uiValuesFactory.create<List<NewsPiece>>(const []);

  late final _loadedProducts = <String, Product>{};
  late final _loadedShops = <OsmUID, Shop>{};

  var _lastLoadedNewsPage = -1;
  var _allNewsLoaded = false;

  UIValueBase<bool> get loading => _loading;
  UIValueBase<GeneralError?> get lastError => _lastError;
  UIValueBase<List<NewsPiece>> get newsPieces => _newsPieces;

  NewsFeedPageModel(this._newsFeedManager, this._productsObtainer,
      this._shopsManager, this._uiValuesFactory);

  Product? getProductWith(String barcode) => _loadedProducts[barcode];
  Shop? getShopWith(OsmUID uid) => _loadedShops[uid];
  Iterable<Shop> getAllLoadedShops() => _loadedShops.values;

  void maybeLoadNextNews() async {
    if (_allNewsLoaded) {
      return;
    }
    _loading.setValue(true);
    _lastError.setValue(null);
    try {
      final result = await _loadNewsImpl();
      if (result.isOk) {
        _lastLoadedNewsPage += 1;
      } else {
        _lastError.setValue(result.unwrapErr());
      }
    } finally {
      _loading.setValue(false);
    }
  }

  Future<Result<None, GeneralError>> _loadNewsImpl() async {
    // Get news
    final newsRes =
        await _newsFeedManager.obtainNews(page: _lastLoadedNewsPage + 1);
    if (newsRes.isErr) {
      return Err(newsRes.unwrapErr());
    }
    final newNews = newsRes.unwrap();
    if (newNews.isEmpty) {
      _allNewsLoaded = true;
      return Ok(None());
    }

    // Extract barcodes and shops UIDs
    final barcodes = <String>{};
    final shopsUIDs = <OsmUID>{};
    for (final newsPiece in newNews) {
      if (newsPiece.type != NewsPieceType.PRODUCT_AT_SHOP) {
        continue;
      }
      final data = newsPiece.typedData as NewsPieceProductAtShop;
      barcodes.add(data.barcode);
      shopsUIDs.add(data.shopUID);
    }

    // Obtain products
    final productsRes = await _productsObtainer.getProducts(barcodes.toList());
    if (productsRes.isErr) {
      return Err(productsRes.unwrapErr().toGeneral());
    }
    for (final product in productsRes.unwrap()) {
      _loadedProducts[product.barcode] = product;
    }

    // Obtain shops
    final shopsRes = await _shopsManager.fetchShopsByUIDs(shopsUIDs);
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr().toGeneral());
    }
    _loadedShops.addAll(shopsRes.unwrap());

    // Finish
    final allNews = _newsPieces.cachedVal.toList();
    allNews.addAll(newNews);
    _newsPieces.setValue(allNews);
    return Ok(None());
  }
}
