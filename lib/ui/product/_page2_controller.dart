import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/outside/products_manager.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';
import 'package:untitled_vegan_app/ui/photos_taker.dart';
import 'package:untitled_vegan_app/ui/product/_init_product_page_model.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '_page_controller_base.dart';
import '_product_images_helper.dart';

class Page2Controller extends PageControllerBase {
  final InitProductPageModel _model;
  final ProductsManager _productsManager;
  final String _doneText;
  final Function() _doneFn;
  
  final Product _initialProduct;

  bool get pageHasData => productHasAllDataForPage(_model.product);
  static bool productHasAllDataForPage(Product product) => product.imageFront != null;

  Page2Controller(
      this._model,
      this._productsManager,
      this._doneText,
      this._doneFn): _initialProduct = _model.product;

  void _longAction(dynamic Function() action) => _model.longAction(action);

  StepperPage build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;

    final content = Column(children: [
      Expanded(
          flex: 1,
          child: Center(child: Text(
              context.strings.init_product_page_packaging_photo,
              style: Theme.of(context).textTheme.headline5))),
      Expanded(
        flex: 5,
        child: SingleChildScrollView(child: InkWell(
            child: ProductImagesHelper.productImageWidget(_model.product, ProductImageType.FRONT),
            onTap: () { _onProductImageTap(context); }),
        ),
      )
    ]);

    final onNextPressed = () async {
      _longAction(() async {
        if (_model.product != _initialProduct) {
          final updatedProduct =
            await _productsManager.createUpdateProduct(_model.product, langCode);
          if (updatedProduct == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.strings.global_something_went_wrong)));
            return;
          }
          _model.setProduct(updatedProduct);
        }
        FocusScope.of(context).unfocus();
        _doneFn.call();
      });
    };
    final buttonNext = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
            key: Key("page2_next_btn"),
            child: Text(_doneText),
            onPressed: pageHasData && !_model.loading ? onNextPressed : null));

    return StepperPage(content, buttonNext, key: Key("page2"));
  }

  void _onProductImageTap(BuildContext context) async {
    final path = await GetIt.I.get<PhotosTaker>().takeAndCropPhoto(context);
    if (path == null) {
      return;
    }
    _model.setProduct(_model.product.rebuildWithImage(
        ProductImageType.FRONT, path));
  }
}
