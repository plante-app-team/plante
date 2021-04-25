import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/ui/product/_init_product_page_model.dart';
import 'package:plante/l10n/strings.dart';

import '_page_controller_base.dart';
import '_product_images_helper.dart';

class Page2Controller extends PageControllerBase {
  final InitProductPageModel _model;
  final String _doneText;

  bool get pageHasData => productHasAllDataForPage(_model.product);
  static bool productHasAllDataForPage(Product product) =>
      product.imageFront != null;

  Page2Controller(InitProductPageModel model, ProductsManager productsManager,
      this._doneText, Function() doneFn)
      : _model = model,
        super(doneFn, productsManager, model);

  void _longAction(dynamic Function() action) => _model.longAction(action);

  StepperPage build(BuildContext context) {
    final content = Column(children: [
      Expanded(
          flex: 1,
          child: Center(
              child: Text(context.strings.init_product_page_packaging_photo,
                  style: Theme.of(context).textTheme.headline5))),
      Expanded(
        flex: 5,
        child: SingleChildScrollView(
          child: InkWell(
              child: ProductImagesHelper.productImageWidget(
                  _model.product, ProductImageType.FRONT,
                  size: 150),
              onTap: () {
                _onProductImageTap(context);
              }),
        ),
      )
    ]);

    final onNextPressed = () {
      _longAction(() async {
        await onDoneClick(context);
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
    _model.setProduct(
        _model.product.rebuildWithImage(ProductImageType.FRONT, path));
  }
}
