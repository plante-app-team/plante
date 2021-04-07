import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/outside/products_manager.dart';
import 'package:untitled_vegan_app/ui/base/stepper/customizable_stepper.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '_init_product_page_model.dart';
import '_page1_controller.dart';
import '_page2_controller.dart';
import '_page3_controller.dart';
import '_page4_controller.dart';
import '_page_controller_base.dart';

typedef DoneCallback = void Function();

class InitProductPage extends StatefulWidget {
  final Product initialProduct;
  final DoneCallback callback;
  final Key? key;

  static bool hasEnoughDataAlready(Product product) =>
      _InitProductPageState._hasEnoughDataAlready(product);

  InitProductPage(this.initialProduct, this.callback, {this.key});

  @override
  _InitProductPageState createState() =>
      _InitProductPageState(initialProduct, callback, this.key);
}

class _InitProductPageState extends State<InitProductPage> with RestorationMixin {
  final Key? key;
  final DoneCallback _callback;

  final InitProductPageModel _model;

  final _stepperController = CustomizableStepperController();

  bool _controllersInited = false;
  final _pagesControllers = <PageControllerBase>[];

  static bool _hasEnoughDataAlready(Product product) {
    return Page1Controller.productHasAllDataForPage(product)
        && Page2Controller.productHasAllDataForPage(product)
        && Page3Controller.productHasAllDataForPage(product)
        && Page4Controller.productHasAllDataForPage(product);
  }

  _InitProductPageState(Product initialProduct, this._callback, this.key)
      : _model = InitProductPageModel(initialProduct);

  /// NOTE: multiple product pages are not supported
  @override
  String? get restorationId => 'init_product_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    for (final property in _model.restorableProperties.entries) {
      registerForRestoration(property.value, property.key);
    }
    _model.loadingChanges.listen((event) {
      setState(() {
        // Boom! Widgets update started
      });
    });
    _model.productChanges.listen((event) {
      setState(() {
        // Boom! Widgets update started
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllersInited) {
      final stepForward = () {
        _stepperController.stepForward();
      };
      final finish = () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.strings.init_product_page_done_thanks)));
        _callback.call();
        Navigator.of(context).pop();
      };
      final productsManager = GetIt.I.get<ProductsManager>();

      final pagesMakers = <_PageControllerMaker>[];
      if (!Page1Controller.productHasAllDataForPage(_model.product)) {
        pagesMakers.add((btnText, btnAction) => Page1Controller(_model, productsManager, btnText, btnAction));
      }
      if (!Page2Controller.productHasAllDataForPage(_model.product)) {
        pagesMakers.add((btnText, btnAction) => Page2Controller(_model, productsManager, btnText, btnAction));
      }
      if (!Page3Controller.productHasAllDataForPage(_model.product)) {
        pagesMakers.add((btnText, btnAction) => Page3Controller(_model, productsManager, btnText, btnAction));
      }
      if (!Page4Controller.productHasAllDataForPage(_model.product)) {
        pagesMakers.add((btnText, btnAction) => Page4Controller(_model, productsManager, btnText, btnAction));
      }

      final lastIndex = pagesMakers.length - 1;
      for (int index = 0; index <= lastIndex; ++index) {
        final String doneText;
        final void Function() doneFn;
        if (index != lastIndex) {
          doneText = context.strings.init_product_page_btn_next;
          doneFn = stepForward;
        } else {
          doneText = context.strings.init_product_page_done;
          doneFn = finish;
        }
        final maker = pagesMakers[index];
        _pagesControllers.add(maker.call(doneText, doneFn));
      }

      _controllersInited = true;
    }

    return Scaffold(
        key: key,
        body: SafeArea(child: Stack(children: [
          if (_model.loading) SizedBox(width: double.infinity, child: LinearProgressIndicator()),
          CustomizableStepper(
            pages: _pagesControllers.map((c) => c.build(context)).toList(),
            controller: _stepperController,
            contentPadding: EdgeInsets.only(left: 50, right: 50),
          )]))
    );
  }
}

typedef _PageControllerMaker = PageControllerBase Function(String, void Function());
