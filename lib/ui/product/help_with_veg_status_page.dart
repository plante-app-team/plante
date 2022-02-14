import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/products/products_manager.dart';
import 'package:plante/products/products_manager_error.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/veg_status_selection_panel.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';

typedef DoneCallback = void Function();
typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class HelpWithVegStatusPage extends PagePlante {
  final Product initialProduct;
  final DoneCallback? doneCallback;
  final ProductUpdatedCallback? productUpdatedCallback;

  const HelpWithVegStatusPage(this.initialProduct,
      {Key? key, this.doneCallback, this.productUpdatedCallback})
      : super(key: key);

  @override
  _HelpWithVegStatusPageState createState() => _HelpWithVegStatusPageState();
}

class _HelpWithVegStatusPageState
    extends PageStatePlante<HelpWithVegStatusPage> {
  final ProductsManager _productsManager = GetIt.I.get<ProductsManager>();

  VegStatus? _vegStatus;
  bool _loading = false;

  _HelpWithVegStatusPageState() : super('HelpWithVegStatusPage');

  @override
  Widget buildPage(BuildContext context) {
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: double.infinity,
          child: Text(
            context.strings.help_with_veg_status_page_title,
            style: TextStyles.headline1,
            textAlign: TextAlign.left,
          )),
      const SizedBox(height: 24),
      Column(key: const Key('vegan_status_group'), children: [
        VegStatusSelectionPanel(
          keyPositive: const Key('vegan_positive_btn'),
          keyNegative: const Key('vegan_negative_btn'),
          keyUnknown: const Key('vegan_unknown_btn'),
          title: context.strings.init_product_page_is_it_vegan,
          vegStatus: _vegStatus,
          onChanged: (value) {
            setState(() {
              _vegStatus = value;
            });
          },
        ),
        const SizedBox(height: 24),
      ]),
      const SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: ButtonFilledPlante.withText(
            context.strings.global_done,
            key: const Key('done_btn'),
            onPressed: _canSave() ? _save : null,
          )),
      const SizedBox(height: 24)
    ]);

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Stack(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeaderPlante(
                            rightAction: FabPlante(
                                onPressed: _cancel,
                                svgAsset: 'assets/cancel.svg')),
                        Container(
                            padding: const EdgeInsets.only(left: 24, right: 24),
                            child: content),
                      ]),
                  AnimatedSwitcher(
                      duration: DURATION_DEFAULT,
                      child: _loading
                          ? const LinearProgressIndicatorPlante()
                          : const SizedBox.shrink())
                ]))));
  }

  bool _canSave() {
    // We don't let the user to select the "possible" status - it's up to
    // moderators.
    return _vegStatus != null && _vegStatus != VegStatus.possible;
  }

  void _save() async {
    Log.i('HelpWithVegStatusPage: _save: start');
    setState(() {
      _loading = true;
    });
    try {
      var savedProduct = widget.initialProduct.rebuild((e) => e
        ..veganStatus = _vegStatus
        ..veganStatusSource = VegStatusSource.community);

      final productResult =
          await _productsManager.createUpdateProduct(savedProduct);
      if (productResult.isOk) {
        Log.i('HelpWithVegStatusPage: _save: product saved');
        analytics.sendEvent(
            'help_with_veg_status_success', {'barcode': savedProduct.barcode});
        savedProduct = productResult.unwrap();
      } else {
        analytics.sendEvent(
            'help_with_veg_status_failure', {'barcode': savedProduct.barcode});
        if (productResult.unwrapErr() == ProductsManagerError.NETWORK_ERROR) {
          showSnackBar(context.strings.global_network_error, context);
        } else {
          showSnackBar(context.strings.global_something_went_wrong, context);
        }
        return;
      }

      widget.productUpdatedCallback?.call(savedProduct);
      widget.doneCallback?.call();
      Navigator.of(context).pop();
      showSnackBar(context.strings.global_done_thanks, context);
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }
}
