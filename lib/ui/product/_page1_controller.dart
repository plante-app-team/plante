import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/outside/products_manager.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';
import 'package:untitled_vegan_app/ui/product/_init_product_page_model.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '_page_controller_base.dart';

class Page1Controller extends PageControllerBase {
  final InitProductPageModel _model;
  final ProductsManager _productsManager;
  final String _doneText;
  final Function() _doneFn;
  
  final Product _initialProduct;

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoriesController = TextEditingController();

  bool get pageHasData => productHasAllDataForPage(_model.product);
  static bool productHasAllDataForPage(Product product) =>
      (product.name ?? "").length >= 3;

  Page1Controller(
      this._model,
      this._productsManager,
      this._doneText,
      this._doneFn): _initialProduct = _model.product {
    _model.productChanges.listen((event) {
      if (event.updater == "first_page_controllers") {
        return;
      }
      _updateControllers(event.product);
    });

    _nameController.addListener(() {
      _model.updateProduct(updater: "first_page_controllers", fn: (v) {
        v.name = _nameController.text;
      });
    });
    _brandController.addListener(() {
      _model.updateProduct(updater: "first_page_controllers", fn: (v) {
        v.brands.clear();
        v.brands.addAll(_textToList(_brandController.text));
      });
    });
    _categoriesController.addListener(() {
      _model.updateProduct(updater: "first_page_controllers", fn: (v) {
        v.categories.clear();
        v.categories.addAll(_textToList(_categoriesController.text));
      });
    });

    _updateControllers(_model.product);
  }

  void _updateControllers(Product product) {
    _nameController.text = product.name ?? "";
    _brandController.text = (product.brands?.toList() ?? []).join(", ");
    _categoriesController.text = (product.categories?.toList() ?? []).join(", ");
  }

  List<String> _textToList(String text) =>
      text.split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  void _longAction(dynamic Function() action) => _model.longAction(action);

  StepperPage build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;

    final content = Column(children: [
      Expanded(
          flex: 1,
          child: Center(child: Text(
              context.strings.init_product_page_add_product_data,
              style: Theme
                  .of(context)
                  .textTheme
                  .headline5))),
      Expanded(
        flex: 5,
        child: Column(children: [
          TextField(
            key: Key("name"),
            decoration: InputDecoration(
              hintText: context.strings.init_product_page_product_name,
              labelText: context.strings.init_product_page_product_name,
            ),
            controller: _nameController,
          ),
          TextField(
            key: Key("brands"),
            decoration: InputDecoration(
              hintText: context.strings.init_product_page_product_brand,
              labelText: context.strings.init_product_page_product_brand,
            ),
            controller: _brandController,
          ),
          TextField(
            key: Key("categories"),
            decoration: InputDecoration(
              hintText: context.strings.init_product_page_product_categories,
              labelText: context.strings.init_product_page_product_categories,
            ),
            controller: _categoriesController,
          ),
        ]),
      )
    ]);

    final onNextPressed = () async {
      _longAction(() async {
        if (_initialProduct != _model.product) {
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
            key: Key("page1_next_btn"),
            child: Text(_doneText),
            onPressed: pageHasData && !_model.loading ? onNextPressed : null));

    return StepperPage(content, buttonNext, key: Key("page1"));
  }
}