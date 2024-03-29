import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/cmds/likes_cmds.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/map/shops_where_product_sold_obtainer.dart';
import 'package:plante/outside/news/news_cluster.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/outside/news/news_piece.dart';
import 'package:plante/outside/news/news_piece_product_at_shop.dart';
import 'package:plante/outside/news/news_piece_type.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

class NewsFeedPageModel {
  final NewsFeedManager _newsFeedManager;
  final ProductsObtainer _productsObtainer;
  final ShopsManager _shopsManager;
  final LatestCameraPosStorage _cameraPosStorage;
  final ShopsWhereProductSoldObtainer _shopsWhereProductSoldObtainer;
  final UserAvatarManager _avatarManager;
  final Backend _backend;

  final UIValuesFactory _uiValuesFactory;

  late final _loading = _uiValuesFactory.create(false);
  late final _reloading = _uiValuesFactory.create(false);
  late final _lastError = _uiValuesFactory.create<GeneralError?>(null);
  late final _news = _uiValuesFactory.create<List<NewsCluster>>(const []);

  late final _loadedProducts = <String, UIValue<Product?>>{};
  late final _loadedShops = <OsmUID, Shop>{};

  var _lastLoadedNewsPage = -1;
  var _allNewsLoaded = false;

  var _lastFirstPageRequestTime = DateTime.fromMicrosecondsSinceEpoch(0);
  Coord? _lastNewsCenter;

  var _newsLifetimeSecs = -1;
  var _newsReloadAfterKms = -1;

  UIValueBase<bool> get loading => _loading;
  UIValueBase<bool> get reloading => _reloading;
  UIValueBase<GeneralError?> get lastError => _lastError;
  UIValueBase<List<NewsCluster>> get news => _news;

  NewsFeedPageModel(
      this._newsFeedManager,
      this._productsObtainer,
      this._shopsManager,
      this._cameraPosStorage,
      this._shopsWhereProductSoldObtainer,
      this._avatarManager,
      this._backend,
      this._uiValuesFactory);

  UIValue<Product?> getProductWith(String barcode) {
    _loadedProducts[barcode] ??= _uiValuesFactory.create(null);
    return _loadedProducts[barcode]!;
  }

  Shop? getShopWith(OsmUID uid) => _loadedShops[uid];
  Iterable<Shop> getAllLoadedShops() => _loadedShops.values;

  void setNewsLifetimeSecs(int newsLifetimeSecs) {
    _newsLifetimeSecs = newsLifetimeSecs;
  }

  void setNewsReloadAfterKms(int newsReloadAfterKms) {
    _newsReloadAfterKms = newsReloadAfterKms;
  }

  void onPageBecameVisible() async {
    final now = DateTime.now();
    final secsSinceLastRequest =
        now.difference(_lastFirstPageRequestTime).inSeconds;
    if (_newsLifetimeSecs < secsSinceLastRequest) {
      await reloadNews();
      return;
    }

    final cameraPos = await _cameraPosStorage.get();
    if (cameraPos != null) {
      final kmsCameraMoved = metersBetween(_lastNewsCenter!, cameraPos) / 1000;
      if (_lastNewsCenter != null && _newsReloadAfterKms < kmsCameraMoved) {
        _lastNewsCenter = cameraPos;
        await reloadNews();
        return;
      }
    } else {
      Log.w('NewsFeedPageModel: no camera position for some reason');
      _lastError.setValue(GeneralError.OTHER);
      return;
    }
  }

  Future<void> reloadNews() async {
    await _maybeLoadNextNews(clearOldNews: true);
  }

  Future<void> maybeLoadNextNews() async {
    await _maybeLoadNextNews();
  }

  Future<void> _maybeLoadNextNews({bool clearOldNews = false}) async {
    if (loading.cachedVal) {
      return;
    }
    if (_allNewsLoaded && !clearOldNews) {
      return;
    }

    _lastNewsCenter ??= await _cameraPosStorage.get();
    if (_lastNewsCenter == null) {
      Log.w('NewsFeedPageModel: no camera position for some reason');
      _lastError.setValue(GeneralError.OTHER);
      return;
    }

    try {
      _loading.setValue(true);
      _lastError.setValue(null);
      if (clearOldNews) {
        _allNewsLoaded = false;
        _lastLoadedNewsPage = -1;
      }
      if (_lastLoadedNewsPage == -1) {
        _reloading.setValue(true);
      }
      final result = await _loadNewsImpl(
          center: _lastNewsCenter!, page: _lastLoadedNewsPage + 1);
      if (result.isOk) {
        if (clearOldNews) {
          _news.setValue(const []);
        }
        _lastLoadedNewsPage += 1;
        final newNews = result.unwrap();
        if (newNews.isEmpty) {
          _allNewsLoaded = true;
        }
        _news.setValue(_news.cachedVal.combineWith(newNews));

        if (_lastLoadedNewsPage == 0) {
          _lastFirstPageRequestTime = DateTime.now();
        }
      } else {
        _lastError.setValue(result.unwrapErr());
      }
    } finally {
      _loading.setValue(false);
      _reloading.setValue(false);
    }
  }

  // Returns loaded news
  Future<Result<List<NewsPiece>, GeneralError>> _loadNewsImpl(
      {required Coord center, required int page}) async {
    // Get news
    final newsRes =
        await _newsFeedManager.obtainNews(center: center, page: page);
    if (newsRes.isErr) {
      return Err(newsRes.unwrapErr());
    }
    final newNews = newsRes.unwrap();
    if (newNews.isEmpty) {
      return Ok(const []);
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
      _loadedProducts[product.barcode] ??= _uiValuesFactory.create(null);
      _loadedProducts[product.barcode]!.setValue(product);
    }

    // Obtain shops
    final shopsRes = await _shopsManager.fetchShopsByUIDs(shopsUIDs);
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr().toGeneral());
    }
    _loadedShops.addAll(shopsRes.unwrap());

    return Ok(newNews);
  }

  Future<Result<List<Shop>, ShopsManagerError>> obtainShopsWhereSold(
      Product product) async {
    final shopsRes = await _shopsWhereProductSoldObtainer
        .fetchShopsWhereSold(product.barcode);
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr());
    }
    return Ok(shopsRes.unwrap().values.toList());
  }

  Uri? authorAvatarUrl(NewsCluster cluster) {
    final newsPiece = cluster.newsPieces.first;
    if (newsPiece.creatorUserAvatarId == null) {
      return null;
    }
    return _avatarManager.otherUserAvatarUri(
        newsPiece.creatorUserId, newsPiece.creatorUserAvatarId!);
  }

  Future<Map<String, String>> authHeaders() {
    return _backend.authHeaders();
  }

  Future<void> reverseLikeState(String barcode) async {
    final product = _loadedProducts[barcode]?.cachedVal;
    if (product == null) {
      return;
    }
    final liked = !product.likedByMe;
    _loadedProducts[barcode]!.setValue(product.rebuild((e) => e
      ..likedByMe = liked
      ..likesCount = product.likesCount + (liked ? 1 : -1)));

    if (liked) {
      await _backend.likeProduct(barcode);
    } else {
      await _backend.unlikeProduct(barcode);
    }
  }
}
