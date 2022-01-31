import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/size_int.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/restorable/product_lang_slice_restorable.dart';
import 'package:plante/model/restorable/product_restorable.dart';
import 'package:plante/model/restorable/shops_list_restorable.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/product_at_shop_source.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/photos/photo_requester.dart';
import 'package:plante/ui/photos/photos_taker.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

enum InitProductPageOcrState {
  NONE,
  IN_PROGRESS,
  SUCCESS,
  FAILURE,
}

enum InitProductPageModelError {
  LANG_CODE_MISSING,
  OTHER,
}

class InitProductPageModel {
  static const OCR_RETRIES_COUNT = 3;
  static const _IMAGES_MIN_SIZE = SizeInt(
    width: 640,
    height: 160,
  );
  static const _NO_PHOTO = -1;
  final dynamic Function() _onProductUpdate;
  final dynamic Function() _forceReloadAllProductData;
  final ProductRestorable _initialProductRestorableFull;
  final ProductLangSliceRestorable _productSliceRestorable;
  final ShopsListRestorable _shopsRestorable;
  final RestorableInt _photoBeingTaken = RestorableInt(_NO_PHOTO);

  InitProductPageOcrState _ocrState = InitProductPageOcrState.NONE;

  Directory? _cacheDir;
  final ProductsManager _productsManager;
  final ShopsManager _shopsManager;
  final PhotosTaker _photosTaker;
  final Analytics _analytics;
  final InputProductsLangStorage _inputProductsLangStorage;
  final UserLangsManager _userLangsManager;

  Product get _initialProductFull => _initialProductRestorableFull.value;
  ProductLangSlice get _initialProductSlice =>
      _initialProductFull.sliceFor(langCode);

  InitProductPageOcrState get ocrState => _ocrState;
  ProductLangSlice get productSlice => _productSliceRestorable.value;
  set productSlice(ProductLangSlice value) {
    _productSliceRestorable.value = value;
    _onProductUpdate.call();
  }

  Product? get productFull => _initialProductFull.updateWith(productSlice);

  List<Shop> get shops => _shopsRestorable.value;
  set shops(List<Shop> value) {
    _shopsRestorable.value = value;
    _onProductUpdate.call();
  }

  LangCode get langCode => productSlice.lang ?? LangCode.en;

  set langCode(LangCode lang) {
    // Build a new slice and keep all the changes of the current
    // slice made by user.
    productSlice = _initialProductFull.sliceFor(lang).rebuild((e) {
      if (productSlice.veganStatus != _initialProductSlice.veganStatus) {
        e.veganStatus = productSlice.veganStatus;
      }
      if (productSlice.name != _initialProductSlice.name) {
        e.name = productSlice.name;
      }
      if (productSlice.ingredientsText !=
          _initialProductSlice.ingredientsText) {
        e.ingredientsText = productSlice.ingredientsText;
      }
      if (productSlice.brands != _initialProductSlice.brands) {
        e.brands = productSlice.brands?.toBuilder();
      }
      if (productSlice.imageFront != _initialProductSlice.imageFront) {
        e.imageFront = productSlice.imageFront;
      }
      if (productSlice.imageIngredients !=
          _initialProductSlice.imageIngredients) {
        e.imageIngredients = productSlice.imageIngredients;
      }
    });
  }

  List<LangCode>? _userLangs;
  List<LangCode> get userLangs {
    final langs = _userLangs ?? [];
    if (!langs.contains(langCode)) {
      // langCode is guaranteed to be not null so return at least it
      langs.add(langCode);
    }
    return langs;
  }

  bool loading = false;

  Map<String, RestorableProperty<Object?>> get restorableProperties {
    return {
      'initial_product_full': _initialProductRestorableFull,
      'product_slice': _productSliceRestorable,
      'shops': _shopsRestorable,
      'photo_being_taken': _photoBeingTaken,
    };
  }

  InitProductPageModel(
      Product initialProduct,
      this._onProductUpdate,
      this._forceReloadAllProductData,
      List<Shop> _initialShops,
      this._productsManager,
      this._shopsManager,
      this._photosTaker,
      this._analytics,
      this._inputProductsLangStorage,
      this._userLangsManager)
      : _initialProductRestorableFull = ProductRestorable(initialProduct),
        _productSliceRestorable = ProductLangSliceRestorable(
            _inputProductsLangStorage.selectedCode != null
                ? initialProduct
                    .sliceFor(_inputProductsLangStorage.selectedCode!)
                : ProductLangSlice.empty),
        _shopsRestorable = ShopsListRestorable(_initialShops) {
    _userLangsManager.getUserLangs().then((value) {
      _userLangs = value.langs.toList();
      if (productSlice == ProductLangSlice.empty) {
        productSlice = initialProduct.sliceFor(
            _inputProductsLangStorage.selectedCode ?? _userLangs!.first);
      }
      _onProductUpdate.call();
    });
  }

  void setPhotoBeingTakenForTests(ProductImageType imageType) {
    if (!isInTests()) {
      throw Exception();
    }
    _photoBeingTaken.value = imageType.index;
  }

  void initPhotoTaker(BuildContext context, Directory cacheDir) async {
    _cacheDir = cacheDir;

    try {
      final lostPhoto =
          await _photosTaker.retrieveLostPhoto(PhotoRequester.PRODUCT_INIT);
      Log.i('InitProductPageModel initPhotoTaker, '
          'lostPhoto: $lostPhoto, '
          '_photoBeingTaken: ${_photoBeingTaken.value}');
      if (lostPhoto == null || _photoBeingTaken.value == _NO_PHOTO) {
        return;
      }
      if (lostPhoto.isErr) {
        Log.w('PhotosTaker error', ex: lostPhoto.unwrapErr());
        return;
      }

      final imageTypeNum =
          _photoBeingTaken.value.clamp(0, ProductImageType.values.length - 1);
      final imageType = ProductImageType.values[imageTypeNum];

      Log.i('InitProductPageModel obtained photo, cropping');
      final outPath = await _photosTaker.cropPhoto(
          lostPhoto.unwrap().path, context, cacheDir,
          minSize: _IMAGES_MIN_SIZE);
      if (outPath == null) {
        Log.i('InitProductPageModel cropping finished without photo');
        return;
      }

      Log.i('InitProductPageModel cropped photo');
      await _onPhotoTaken(imageType, outPath);
    } finally {
      _photoBeingTaken.value = _NO_PHOTO;
    }
  }

  Future<Result<None, InitProductPageModelError>> takePhoto(
      ProductImageType imageType, BuildContext context) async {
    if (_cacheDir == null) {
      Log.i('InitProductPageModel: takePhoto return because no cache dir');
      return Err(InitProductPageModelError.OTHER);
    }
    _photoBeingTaken.value = imageType.index;
    try {
      Log.i('InitProductPageModel: takePhoto start, imageType: $imageType');
      final outPath = await _photosTaker.takeAndCropPhoto(
          context, _cacheDir!, PhotoRequester.PRODUCT_INIT,
          minSize: _IMAGES_MIN_SIZE);
      if (outPath == null) {
        Log.i('InitProductPageModel: takePhoto, outPath == null');
        // Cancelled
        return Ok(None());
      }
      Log.i('InitProductPageModel: takePhoto success');
      return await _onPhotoTaken(imageType, outPath);
    } finally {
      _photoBeingTaken.value = _NO_PHOTO;
    }
  }

  bool askForLanguage() {
    return true;
  }

  bool askForFrontPhoto() {
    if (_initialProductSlice.imageFront != productSlice.imageFront) {
      // Already updated (probably when different lang was chosen), so
      // we allow further editing.
      return true;
    }
    return _initialProductSlice.imageFront == null;
  }

  bool askForName() {
    if (_initialProductSlice.name != productSlice.name) {
      // Already updated (probably when different lang was chosen), so
      // we allow further editing.
      return true;
    }
    return _initialProductSlice.name == null ||
        _initialProductSlice.name!.trim().isEmpty;
  }

  bool askForBrand() {
    if (_initialProductSlice.brands != productSlice.brands) {
      // Already updated (probably when different lang was chosen), so
      // we allow further editing.
      return true;
    }
    return _initialProductSlice.brands == null ||
        _initialProductSlice.brands!.isEmpty;
  }

  bool askForIngredientsData() {
    if (_initialProductSlice.ingredientsText != productSlice.ingredientsText) {
      // Already updated (probably when different lang was chosen), so
      // we allow further editing.
      return true;
    }
    return _initialProductSlice.ingredientsText == null ||
        _initialProductSlice.ingredientsText!.trim().isEmpty ||
        _initialProductSlice.imageIngredients == null;
  }

  bool askForIngredientsText() {
    return askForIngredientsData() && productSlice.imageIngredients != null;
  }

  bool askForShops() {
    return true;
  }

  bool askForVeganStatus() {
    if (_initialProductSlice.veganStatus != productSlice.veganStatus) {
      return true;
    }
    return _initialProductSlice.veganStatus == null ||
        _initialProductSlice.veganStatusSource == null ||
        _initialProductSlice.veganStatusSource ==
            VegStatusSource.open_food_facts;
  }

  bool canSaveProduct() {
    return ProductPageWrapper.isProductFilledEnoughForDisplay(
        productSlice.buildSingleLangProduct());
  }

  Future<Result<Product, InitProductPageModelError>> saveProduct() async {
    Log.i('InitProductPageModel: saveProduct: start');
    loading = true;
    _onProductUpdate.call();
    try {
      var savedProductSlice = productSlice;
      if (askForVeganStatus()) {
        savedProductSlice = savedProductSlice
            .rebuild((e) => e.veganStatusSource = VegStatusSource.community);
      }
      var savedProduct = _initialProductFull.updateWith(savedProductSlice);

      final productResult =
          await _productsManager.createUpdateProduct(savedProduct);
      if (productResult.isOk) {
        Log.i('InitProductPageModel: saveProduct: product saved');
        savedProduct = productResult.unwrap();
        productSlice = savedProduct.sliceFor(langCode);
      } else {
        _analytics.sendEvent(
            'product_save_failure', {'barcode': productSlice.barcode});
        return Err(InitProductPageModelError.OTHER);
      }

      if (shops.isNotEmpty) {
        Log.i('InitProductPageModel: saveProduct: saving shops');
        final shopsResult = await _shopsManager.putProductToShops(
            savedProduct, shops, ProductAtShopSource.MANUAL);
        if (shopsResult.isErr) {
          _analytics.sendEvent(
              'product_save_shops_failure', {'barcode': productSlice.barcode});
          Log.i('InitProductPageModel: saveProduct: saving shops fail');
          return Err(InitProductPageModelError.OTHER);
        }
      }

      _inputProductsLangStorage.selectedCode = langCode;
      _analytics
          .sendEvent('product_save_success', {'barcode': productSlice.barcode});
      Log.i('InitProductPageModel: saveProduct: success');
      return Ok(savedProduct);
    } finally {
      loading = false;
      _onProductUpdate.call();
    }
  }

  Future<Result<None, InitProductPageModelError>> _onPhotoTaken(
      ProductImageType imageType, Uri outPath) async {
    productSlice = productSlice.rebuildWithImage(imageType, outPath);

    if (imageType != ProductImageType.INGREDIENTS) {
      return Ok(None());
    }

    return performOcr();
  }

  Future<Result<None, InitProductPageModelError>> performOcr() async {
    try {
      Log.i('InitProductPage: performOcr start');
      _ocrState = InitProductPageOcrState.IN_PROGRESS;
      _onProductUpdate.call();

      final ingredientsText = await _ocrIngredientsImpl(langCode);
      if (ingredientsText != null) {
        Log.i('InitProductPage: performOcr success: $ingredientsText');
        _ocrState = InitProductPageOcrState.SUCCESS;
        productSlice =
            productSlice.rebuild((e) => e.ingredientsText = ingredientsText);
        _forceReloadAllProductData.call();
        return Ok(None());
      } else {
        Log.i('InitProductPage: performOcr fail');
        _ocrState = InitProductPageOcrState.FAILURE;
        return Err(InitProductPageModelError.OTHER);
      }
    } finally {
      _onProductUpdate.call();
    }
  }

  Future<String?> _ocrIngredientsImpl(LangCode langCode) async {
    var initialProductWithIngredientsPhoto =
        _initialProductFull.rebuildWithImage(ProductImageType.INGREDIENTS,
            productSlice.imageIngredients, langCode);
    if (!initialProductWithIngredientsPhoto.langsPrioritized
        .contains(langCode)) {
      initialProductWithIngredientsPhoto = initialProductWithIngredientsPhoto
          .rebuild((e) => e.langsPrioritized.add(langCode));
    }

    var attemptsCount = 1;
    Result<ProductWithOCRIngredients, ProductsManagerError> ocrResult =
        Err(ProductsManagerError.OTHER);
    while (attemptsCount <= OCR_RETRIES_COUNT &&
        (ocrResult.isErr || ocrResult.unwrap().ingredients == null)) {
      attemptsCount += 1;
      try {
        ocrResult = await _productsManager
            .updateProductAndExtractIngredients(
                initialProductWithIngredientsPhoto, langCode)
            .timeout(const Duration(seconds: 7));
      } on TimeoutException catch (e) {
        Log.w('_ocrIngredientsImpl timeout $attemptsCount', ex: e);
      }
      if (ocrResult.isErr) {
        if (attemptsCount == OCR_RETRIES_COUNT) {
          _analytics.sendEvent('ocr_fail_final');
        } else {
          _analytics.sendEvent('ocr_fail_will_retry');
        }
      }
    }

    if (ocrResult.isErr) {
      return null;
    }
    if (ocrResult.isOk) {
      _analytics.sendEvent('ocr_success');
    }
    return ocrResult.unwrap().ingredients;
  }
}
