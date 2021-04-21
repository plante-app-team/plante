import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/ui/base/stepper/customizable_stepper.dart';
import 'package:plante/l10n/strings.dart';

import '_init_product_page_model.dart';
import '_page1_controller.dart';
import '_page2_controller.dart';
import '_page3_controller.dart';
import '_page4_controller.dart';
import '_page_controller_base.dart';

typedef DoneCallback = void Function();
typedef ProductUpdatedCallback = void Function(Product updatedProduct);

enum InitProductSubpage {
  PAGE1,
  PAGE2,
  PAGE3,
  PAGE4
}

class InitProductPage extends StatefulWidget {
  final Product initialProduct;
  final DoneCallback? doneCallback;
  final ProductUpdatedCallback? productUpdatedCallback;
  final List<InitProductSubpage>? requiredPages;
  final Key? key;

  InitProductPage(
      this.initialProduct,
      {this.doneCallback,
       this.productUpdatedCallback,
       this.key,
       this.requiredPages});

  @override
  _InitProductPageState createState() => _InitProductPageState(
      initialProduct,
      doneCallback,
      productUpdatedCallback,
      key,
      requiredPages);
}

class _InitProductPageState extends State<InitProductPage> with RestorationMixin {
  final Key? _key;
  final DoneCallback? _doneCallback;
  final ProductUpdatedCallback? _productUpdatedCallback;
  final List<InitProductSubpage>? _requiredPages;

  final InitProductPageModel _model;

  final _stepperController = CustomizableStepperController();

  bool _controllersInited = false;
  final _pagesControllers = <PageControllerBase>[];

  _InitProductPageState(
      Product initialProduct,
      this._doneCallback,
      this._productUpdatedCallback,
      this._key,
      this._requiredPages)
      : _model = InitProductPageModel(initialProduct) {
    assert(_requiredPages == null || _requiredPages!.isNotEmpty);
  }

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
        _productUpdatedCallback?.call(event.product);
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
        _doneCallback?.call();
        Navigator.of(context).pop();
      };
      final productsManager = GetIt.I.get<ProductsManager>();

      final allPagesMakers = <_PageControllerMaker>[];
      allPagesMakers.add((btnText, btnAction) =>
          Page1Controller(_model, productsManager, btnText, btnAction));
      allPagesMakers.add((btnText, btnAction) =>
          Page2Controller(_model, productsManager, btnText, btnAction));
      allPagesMakers.add((btnText, btnAction) =>
          Page3Controller(_model, productsManager, btnText, btnAction));
      allPagesMakers.add((btnText, btnAction) =>
          Page4Controller(_model, productsManager, btnText, btnAction));

      final pagesMakers = <_PageControllerMaker>[];
      if (_requiredPages != null) {
        if (_requiredPages!.contains(InitProductSubpage.PAGE1)) {
          pagesMakers.add(allPagesMakers[0]);
        }
        if (_requiredPages!.contains(InitProductSubpage.PAGE2)) {
          pagesMakers.add(allPagesMakers[1]);
        }
        if (_requiredPages!.contains(InitProductSubpage.PAGE3)) {
          pagesMakers.add(allPagesMakers[2]);
        }
        if (_requiredPages!.contains(InitProductSubpage.PAGE4)) {
          pagesMakers.add(allPagesMakers[3]);
        }
      } else {
        if (!Page1Controller.productHasAllDataForPage(_model.product)) {
          pagesMakers.add(allPagesMakers[0]);
        }
        if (!Page2Controller.productHasAllDataForPage(_model.product)) {
          pagesMakers.add(allPagesMakers[1]);
        }
        if (!Page3Controller.productHasAllDataForPage(_model.product)) {
          pagesMakers.add(allPagesMakers[2]);
        }
        if (!Page4Controller.productHasAllDataForPage(_model.product)) {
          pagesMakers.add(allPagesMakers[3]);
        }
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
        key: _key,
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
