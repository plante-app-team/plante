import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/shops_where_product_sold_obtainer.dart';
import 'package:plante/products/viewed_products_storage.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/product/help_with_veg_status_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/product_report_dialog.dart';

class DisplayProductsPageModel implements UserLangsManagerObserver {
  final Product _initialProduct;
  late final _product = _uiValuesFactory.create(_initialProduct);
  late final _userLangs = _uiValuesFactory.create<List<LangCode>?>(null);
  late final _shopsWhereSold = _uiValuesFactory.create<List<Shop>?>(null);
  final UserParams _user;
  final UserLangsManager _userLangsManager;
  final UserReportsMaker _userReportsMaker;
  final ViewedProductsStorage _viewedProductsStorage;
  final ShopsWhereProductSoldObtainer _shopsWhereProductSoldObtainer;
  final ArgCallback<Product>? _productUpdatedCallback;
  final UIValuesFactory _uiValuesFactory;

  UIValueBase<Product> get product => _product;
  UIValueBase<List<LangCode>?> get userLangs => _userLangs;
  UIValueBase<List<Shop>?> get shopsWhereSold => _shopsWhereSold;
  UserParams get user => _user;

  DisplayProductsPageModel(
      this._initialProduct,
      this._productUpdatedCallback,
      UserParamsController userParamsController,
      this._userLangsManager,
      this._userReportsMaker,
      this._viewedProductsStorage,
      this._shopsWhereProductSoldObtainer,
      this._uiValuesFactory)
      : _user = userParamsController.cachedUserParams!;

  Future<void> init() async {
    await _viewedProductsStorage.addProduct(_initialProduct);
    await _userLangsManager.getUserLangs().then(onUserLangsChange);
    _userLangsManager.addObserver(this);
    await _fetchShopsWhereSold();
  }

  Future<void> _fetchShopsWhereSold() async {
    final shopsRes = await _shopsWhereProductSoldObtainer
        .fetchShopsWhereSold(_initialProduct.barcode);
    if (shopsRes.isOk) {
      _shopsWhereSold.setValue(shopsRes.unwrap().values.toList());
    }
  }

  void dispose() {
    _userLangsManager.removeObserver(this);
  }

  @override
  void onUserLangsChange(UserLangs userLangs) {
    _userLangs.setValue(userLangs.langs.toList());
  }

  void fillLackingData(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InitProductPage(product.cachedVal,
                  key: const Key('init_product_page'),
                  productUpdatedCallback: (product) {
                _productUpdatedCallback?.call(product);
                _product.setValue(product);
              })),
    );
  }

  void helpWithVegStatus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => HelpWithVegStatusPage(product.cachedVal,
                  key: const Key('help_with_veg_status_page'),
                  productUpdatedCallback: (product) {
                _productUpdatedCallback?.call(product);
                _product.setValue(product);
              })),
    );
  }

  void reportProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ProductReportDialog(
            barcode: _product.cachedVal.barcode,
            reportsMaker: _userReportsMaker);
      },
    );
  }
}
