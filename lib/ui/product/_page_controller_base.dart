import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/base/either_extension.dart';
import 'package:untitled_vegan_app/outside/products/products_manager.dart';
import 'package:untitled_vegan_app/outside/products/products_manager_error.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';
import 'package:untitled_vegan_app/ui/base/ui_utils.dart';
import 'package:untitled_vegan_app/ui/product/_init_product_page_model.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

abstract class PageControllerBase {
  final Function() _doneFn;
  final ProductsManager _productsManager;
  final InitProductPageModel _model;
  PageControllerBase(this._doneFn, this._productsManager, this._model);

  StepperPage build(BuildContext context);

  Future<void> onDoneClick(BuildContext context) async {
    final langCode = Localizations.localeOf(context).languageCode;

    final updatedProductResult =
        await _productsManager.createUpdateProduct(_model.product, langCode);
    if (updatedProductResult.isRight) {
      if (updatedProductResult.requireRight() == ProductsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
      return;
    }
    _model.setProduct(updatedProductResult.requireLeft());
    FocusScope.of(context).unfocus();
    _doneFn.call();
  }
}
