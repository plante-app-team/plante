import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_manager_error.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/product/_init_product_page_model.dart';
import 'package:plante/l10n/strings.dart';

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
    if (updatedProductResult.isErr) {
      if (updatedProductResult.unwrapErr() == ProductsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
      return;
    }
    _model.setProduct(updatedProductResult.unwrap());
    FocusScope.of(context).unfocus();
    _doneFn.call();
  }
}
