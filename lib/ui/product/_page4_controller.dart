import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/outside/products_manager.dart';
import 'package:untitled_vegan_app/ui/base/stepper/stepper_page.dart';
import 'package:untitled_vegan_app/ui/product/_init_product_page_model.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '_page_controller_base.dart';

class Page4Controller extends PageControllerBase {
  final InitProductPageModel _model;
  final ProductsManager _productsManager;
  final String _doneText;
  final Function() _doneFn;
  
  final Product _initialProduct;

  Product get _product => _model.product;
  bool get _loading => _model.loading;
  bool get pageHasData => productHasAllDataForPage(_product);
  static bool productHasAllDataForPage(Product product) =>
      product.vegetarianStatus != null && product.veganStatus != null;

  VegStatus? get vegetarianStatus => _product.vegetarianStatus;
  VegStatus? get veganStatus => _product.veganStatus;
  set vegetarianStatus(VegStatus? val) {
    _model.updateProduct(fn: (v) => v.vegetarianStatus = val);
    if (val == VegStatus.negative
        || val == VegStatus.possible
        || val == VegStatus.unknown) {
      // 100% of not-vegetarian products are also not-vegan,
      // same goes for possibly vegetarian and uknown.
      veganStatus = val;
    }
  }
  set veganStatus(VegStatus? val) {
    _model.updateProduct(fn: (v) => v.veganStatus = val);
    if (val == VegStatus.positive) {
      // 100% of vegan products are also vegetarian
      vegetarianStatus = val;
    }
  }

  Page4Controller(
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
              context.strings.init_product_page_veg_status_title,
              style: Theme.of(context).textTheme.headline5))),
      Expanded(
        flex: 5,
        child: SingleChildScrollView(child: Column(children: [
          SizedBox(width: double.infinity, child: Text(context.strings.init_product_page_is_vegetarian_q)),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.positive,
                groupValue: vegetarianStatus,
                onChanged: (VegStatus? value) {
                  vegetarianStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_definitely_yes),
                onTap: () {
                  vegetarianStatus = VegStatus.positive;
                }),
          ]),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.negative,
                groupValue: vegetarianStatus,
                onChanged: (VegStatus? value) {
                  vegetarianStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_definitely_no),
                onTap: () {
                  vegetarianStatus = VegStatus.negative;
                }),
          ]),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.possible,
                groupValue: vegetarianStatus,
                onChanged: (VegStatus? value) {
                  vegetarianStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_possibly),
                onTap: () {
                  vegetarianStatus = VegStatus.possible;
                }),
            InkWell(
                child: Icon(Icons.zoom_out_map_outlined),
                onTap: () { _showPossibleVegStatusTooltip(context); },
            ),
          ]),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.unknown,
                groupValue: vegetarianStatus,
                onChanged: (VegStatus? value) {
                  vegetarianStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_not_sure),
                onTap: () {
                  vegetarianStatus = VegStatus.unknown;
                }),
          ]),

          SizedBox(height: 50),

          SizedBox(width: double.infinity, child: Text(context.strings.init_product_page_is_vegan_q)),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.positive,
                groupValue: veganStatus,
                onChanged: (VegStatus? value) {
                  veganStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_definitely_yes),
                onTap: () {
                  veganStatus = VegStatus.positive;
                }),
          ]),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.negative,
                groupValue: veganStatus,
                onChanged: (VegStatus? value) {
                  veganStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_definitely_no),
                onTap: () {
                  veganStatus = VegStatus.negative;
                }),
          ]),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.possible,
                groupValue: veganStatus,
                onChanged: (VegStatus? value) {
                  veganStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_possibly),
                onTap: () {
                  veganStatus = VegStatus.possible;
                }),
            InkWell(
              child: Icon(Icons.zoom_out_map_outlined),
              onTap: () { _showPossibleVegStatusTooltip(context); },
            ),
          ]),
          Row(children: [
            Radio<VegStatus>(
                value: VegStatus.unknown,
                groupValue: veganStatus,
                onChanged: (VegStatus? value) {
                  veganStatus = value;
                }),
            InkWell(
                child: Text(context.strings.init_product_page_not_sure),
                onTap: () {
                  veganStatus = VegStatus.unknown;
                }),
          ]),
        ])),
      )
    ]);

    final onNextPressed = () async {
      _longAction(() async {
        if (_initialProduct != _product) {
          final updatedProduct = await _productsManager.updateProduct(
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
      });
    };
    final buttonNext = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
            key: Key("page4_next_btn"),
            child: Text(_doneText),
            onPressed: pageHasData && !_loading ? onNextPressed : null));

    return StepperPage(content, buttonNext, key: Key("page4"));
  }

  void _showPossibleVegStatusTooltip(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text(''),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(context.strings.init_product_page_possible_status_explanation),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.strings.init_product_page_possible_status_explanation_ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
