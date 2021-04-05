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

class Page3Controller extends PageControllerBase {
  final InitProductPageModel _model;
  final ProductsManager _productsManager;
  final String _doneText;
  final Function() _doneFn;
  
  final Product _initialProduct;

  final _ingredientsController = TextEditingController();
  final _ingredientsFocusNode = FocusNode();

  Product get _product => _model.product;
  bool get _loading => _model.loading;

  bool get pageHasData => productHasAllDataForPage(_product);
  static bool productHasAllDataForPage(Product product) =>
      product.imageIngredients != null && (product.ingredients ?? "").isNotEmpty;

  Page3Controller(
      this._model,
      this._productsManager,
      this._doneText,
      this._doneFn): _initialProduct = _model.product {
    _model.productChanges.listen((event) {
      if (event.updater == "third_page_controllers") {
        return;
      }
      _updateController(event.product);
    });

    _ingredientsController.addListener(() {
      _model.updateProduct(updater: "third_page_controllers", fn: (v) {
        v.ingredients = _ingredientsController.text;
      });
    });
    _updateController(_product);

    _model.ocrAllowed = _product.imageIngredients != null;
  }

  void _updateController(Product product) {
    _ingredientsController.text = product.ingredients ?? "";
  }

  void _longAction(dynamic Function() action) => _model.longAction(action);

  StepperPage build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;

    final ingredientsTextWidget = _ingredientsTextWidget(context, langCode);
    final content = Column(children: [
      Expanded(
          flex: 1,
          child: Center(child: Text(
              context.strings.init_product_page_ingredients,
              style: Theme.of(context).textTheme.headline5))),
      Expanded(
        flex: 5,
        child: SingleChildScrollView(child: Column(children: [
          InkWell(
              child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: ProductImagesHelper.productImageWidget(
                      _product, ProductImageType.INGREDIENTS)),
              onTap: () async { _onProductImageTap(context); }),
          if (ingredientsTextWidget != null) ingredientsTextWidget
        ])),
      )
    ]);

    final onNextPressed = () async {
      if (_initialProduct != _product) {
        final updatedProduct = await _productsManager.createUpdateProduct(
            _product, langCode);
        if (updatedProduct == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context.strings.global_something_went_wrong)));
          return;
        }
        _model.setProduct(updatedProduct);
      }
      FocusScope.of(context).unfocus();
      _doneFn.call();
    };
    final buttonNext = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
            key: Key("page3_next_btn"),
            child: Text(_doneText),
            onPressed: pageHasData && !_loading ? onNextPressed : null));

    return StepperPage(content, buttonNext, key: Key("page3"));
  }

  Widget? _ingredientsTextWidget(BuildContext context, String langCode) {
    final Widget? ocrWidget;
    if (_model.ocrAllowed) {
      final performOcr = () async {
        _longAction(() async {
          final result = await _productsManager
              .updateProductAndExtractIngredients(_product, langCode);
          if (result == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.strings.global_something_went_wrong)));
            return;
          }
          _model.setProduct(result.product);

          final ocrIngredients = result.ingredients;
          if (ocrIngredients == null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.strings.global_something_went_wrong)));
            return;
          }
          _model.updateProduct(fn: (v) => v.ingredients = ocrIngredients);
          _model.ocrAllowed = false;
          _model.ocrNeedsVerification = true;
        });
      };
      ocrWidget = OutlinedButton(
          child: Text(context.strings.init_product_page_ingredients_ocr),
          onPressed: performOcr);
    } else if (_model.ocrNeedsVerification) {
      ocrWidget = Column(children: [
        SizedBox(width: double.infinity, child: Text(context.strings.init_product_page_ingredients_ocr_ok_q)),
        Row(children: [
          OutlinedButton(
              child: Text(context.strings.init_product_page_yes),
              onPressed: () {
                _model.ocrNeedsVerification = false;
              }),
          OutlinedButton(
              child: Text(context.strings.init_product_page_no),
              onPressed: () {
                _model.ocrNeedsVerification = false;
                FocusScope.of(context).requestFocus(_ingredientsFocusNode);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(context.strings.init_product_page_please_edit_ingredients)));
              })
        ])
      ]);
    } else {
      ocrWidget = null;
    }

    final Widget? ingredientsTextField;
    if (_product.imageIngredients != null) {
      ingredientsTextField = TextField(
          key: Key("ingredients"),
          // keyboardType: TextInputType.multiline,
          maxLines: null,
          decoration: InputDecoration(
            hintText: context.strings.init_product_page_ingredients,
            labelText: context.strings.init_product_page_ingredients,
          ),
          controller: _ingredientsController,
          focusNode: _ingredientsFocusNode);
    } else {
      ingredientsTextField = null;
    }

    return Column(children: [
      if (ocrWidget != null) ocrWidget,
      if (ingredientsTextField != null) ingredientsTextField
    ]);
  }

  void _onProductImageTap(BuildContext context) async {
    final path = await GetIt.I.get<PhotosTaker>().takeAndCropPhoto(context);
    if (path == null) {
      return;
    }
    _model.setProduct(_product.rebuildWithImage(
        ProductImageType.INGREDIENTS, path));
    _model.ocrAllowed = true;
  }
}
