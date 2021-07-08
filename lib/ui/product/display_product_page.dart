import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/model/moderator_choice_reason.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/model/product.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/expandable_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/info_button_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/components/menu_item_plante.dart';
import 'package:plante/ui/base/components/veg_status_displayed.dart';
import 'package:plante/ui/base/my_stateful_builder.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/moderator_comment_dialog.dart';
import 'package:plante/ui/product/product_photo_page.dart';
import 'package:plante/ui/product/product_report_dialog.dart';
import 'package:plante/ui/product/veg_statuses_explanation_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: always_use_package_imports
import 'product_header_widget.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class DisplayProductPage extends StatefulWidget {
  final Product _initialProduct;
  final ProductUpdatedCallback? productUpdatedCallback;

  const DisplayProductPage(this._initialProduct,
      {Key? key, this.productUpdatedCallback})
      : super(key: key);

  @override
  _DisplayProductPageState createState() =>
      _DisplayProductPageState(_initialProduct, productUpdatedCallback);
}

class _DisplayProductPageState extends PageStatePlante<DisplayProductPage> {
  Product product;
  final Backend backend;
  final UserParams user;
  final ProductUpdatedCallback? productUpdatedCallback;

  final expandController = ExpandableController();
  bool loading = false;

  final menuButtonKey = GlobalKey();

  _DisplayProductPageState(this.product, this.productUpdatedCallback)
      : backend = GetIt.I.get<Backend>(),
        user = GetIt.I.get<UserParamsController>().cachedUserParams!,
        super('DisplayProductPage') {
    GetIt.I.get<ViewedProductsStorage>().addProduct(product);
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Stack(children: [
          Column(children: [
            HeaderPlante(
              leftAction: FabPlante.backBtnPopOnClick(
                  key: const Key('back_button'), heroTag: 'left_action'),
              // Sized box is only for the key
              rightAction: SizedBox(
                  key: const Key('options_button'),
                  child: FabPlante.menuBtn(
                      key: menuButtonKey,
                      heroTag: 'right_action',
                      onPressed: _showProductMenu)),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Column(children: [
                  const SizedBox(height: 12),
                  ProductHeaderWidget(
                      key: const Key('product_header'),
                      product: product,
                      imageType: ProductImageType.FRONT,
                      onTap: _showProductPhoto,
                      onLongPress: _copyProductName),
                ])),
            const SizedBox(height: 19),
            Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(children: [
                  InkWell(
                    onTap:
                        _askForVegStatusHelp() ? _onVegStatusHelpClick : null,
                    child: VegStatusDisplayed(
                        product: product,
                        user: user,
                        onVegStatusSourceClick:
                            _onVegStatusSourceClickCallback(),
                        helpText: _askForVegStatusHelp()
                            ? context.strings
                                .display_product_page_click_to_help_with_veg_statuses
                            : null,
                        onHelpClick: _onVegStatusHelpClick),
                  ),
                ])),
            const SizedBox(height: 16),
            if (_vegStatusHint() != null)
              Padding(
                  key: const Key('veg_status_hint'),
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 12, top: 8, right: 12, bottom: 8),
                        child: Text(_vegStatusHint()!, style: TextStyles.hint),
                      ))),
            const SizedBox(height: 16),
            Column(children: [
              Container(
                  width: double.infinity,
                  height: 96,
                  color: ColorsPlante.primary,
                  child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('mark_on_map'),
                        overlayColor:
                            MaterialStateProperty.all(ColorsPlante.splashColor),
                        onTap: _markOnMap,
                        child: Center(
                            child: Text(
                                context.strings
                                    .display_product_page_veg_mark_on_map,
                                style: TextStyles.buttonFilled)),
                      ))),
              const SizedBox(height: 16),
            ]),
            InkWell(
                onTap: _showProductIngredientsPhoto,
                onLongPress: _copyIngredientsList,
                child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Column(children: [
                      SizedBox(
                          width: double.infinity,
                          child: Text(
                              context.strings.display_product_page_ingredients,
                              style: TextStyles.normalBold)),
                      const SizedBox(height: 8),
                      if (product.ingredientsText != null)
                        SizedBox(
                            key: const Key('product_ingredients_text'),
                            width: double.infinity,
                            child: Text(product.ingredientsText!,
                                style: TextStyles.normal)),
                      if (product.ingredientsText == null)
                        ProductHeaderWidget(
                            key: const Key('product_ingredients_photo'),
                            product: product,
                            imageType: ProductImageType.INGREDIENTS,
                            onTap: _showProductIngredientsPhoto),
                      const SizedBox(height: 24),
                    ]))),
            if (_haveIngredientsAnalysis()) _ingredientsAnalysisWidget(),
            const SizedBox(height: 16)
          ]),
        ]))));
  }

  String? _vegStatusHint() {
    switch (_vegStatus()) {
      case VegStatus.positive:
        return context.strings.display_product_page_veg_status_positive_warning;
      case VegStatus.negative:
        return null;
      case VegStatus.possible:
        return context
            .strings.display_product_page_veg_status_possible_explanation;
      case VegStatus.unknown:
        return context
            .strings.display_product_page_veg_status_unknown_explanation;
    }
  }

  Widget _ingredientsAnalysisWidget() {
    if (product.ingredientsAnalyzed?.length == 1) {
      return _ingredientsAnalysisWidgetWithLines(9999);
    }
    return ExpandablePlante(
      collapsed: _ingredientsAnalysisWidgetWithLines(1),
      expanded: Column(children: [
        _ingredientsAnalysisWidgetWithLines(9999),
        const SizedBox(height: 58)
      ]),
    );
  }

  Column _ingredientsAnalysisWidgetWithLines(int lines) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(children: [
            Text(context.strings.display_product_page_ingredients_analysis,
                style: TextStyles.normalBold),
            InfoButtonPlante(onTap: _showVegStatusesExplanation)
          ])),
      const SizedBox(height: 16),
      _ingredientsAnalysisTable(lines)
    ]);
  }

  bool _askForVegStatusHelp() {
    return _vegStatusSource() == VegStatusSource.open_food_facts;
  }

  void _onVegStatusHelpClick() {
    analytics.sendEvent('help_with_vegan_statuses_started');
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InitProductPage(product,
                  key: const Key('init_product_page'),
                  title: context
                      .strings.display_product_page_help_with_veg_statuses,
                  productUpdatedCallback: (product) {
                productUpdatedCallback?.call(product);
                setState(() {
                  this.product = product;
                });
              })),
    );
  }

  VegStatus _vegStatus() {
    VegStatus? status;
    if (user.eatsVeggiesOnly ?? true) {
      status = product.veganStatus;
    } else {
      status = product.vegetarianStatus;
    }
    return status ?? VegStatus.unknown;
  }

  VegStatusSource _vegStatusSource() {
    VegStatusSource? source;
    if (user.eatsVeggiesOnly ?? true) {
      source = product.veganStatusSource;
    } else {
      source = product.vegetarianStatusSource;
    }
    if (source == null || source == VegStatusSource.unknown) {
      source = VegStatusSource.community;
    }
    return source;
  }

  VoidCallback? _onVegStatusSourceClickCallback() {
    if (_vegStatusSource() != VegStatusSource.moderator ||
        _vegStatusModeratorChoiceReason() == null) {
      return null;
    }
    return () {
      _onVegStatusSourceTextClick(context);
    };
  }

  ModeratorChoiceReason? _vegStatusModeratorChoiceReason() {
    if (user.eatsVeggiesOnly ?? true) {
      return product.moderatorVeganChoiceReason;
    } else {
      return product.moderatorVegetarianChoiceReason;
    }
  }

  String? _vegStatusModeratorChoiceReasonText() {
    return _vegStatusModeratorChoiceReason()?.localize(context);
  }

  String? _vegStatusModeratorSourcesText() {
    if (user.eatsVeggiesOnly ?? true) {
      return product.moderatorVeganSourcesText;
    } else {
      return product.moderatorVegetarianSourcesText;
    }
  }

  void _onVegStatusSourceTextClick(BuildContext context) {
    analytics.sendEvent('moderator_comment_dialog_shown');
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ModeratorCommentDialog(
              user: user,
              product: product,
              onSourceUrlClick: (url) {
                analytics.sendEvent('moderator_comment_source_url_click');
                launch(url);
              });
        });
  }

  bool _haveIngredientsAnalysis() =>
      product.ingredientsAnalyzed != null &&
      product.ingredientsAnalyzed!.isNotEmpty;

  Widget _ingredientsAnalysisTable(int maxLines) {
    final rows = <TableRow>[];
    const rowHeight = 30.0;

    const colorGrey = Color(0xFFF6F7FA);
    const colorWhite = Colors.white;
    bool nextColorGrey = true;
    final nextColor = () {
      final nextColorVal = nextColorGrey ? colorGrey : colorWhite;
      nextColorGrey = !nextColorGrey;
      return nextColorVal;
    };

    final center = (Widget child) {
      return SizedBox(
          height: rowHeight,
          child: Center(child: SizedBox(width: double.infinity, child: child)));
    };

    rows.add(TableRow(children: [
      const SizedBox(width: 24),
      center(Text(context.strings.display_product_page_table_column1,
          style: TextStyles.normalBold)),
      center(Text(context.strings.display_product_page_table_column2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.normalBold)),
      const SizedBox(width: 12),
      center(Text(context.strings.display_product_page_table_column3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.normalBold)),
      const SizedBox(width: 24),
    ], decoration: BoxDecoration(color: nextColor())));
    final ingredients = product.ingredientsAnalyzed!;
    var linesCount = 0;
    for (final ingredient in ingredients) {
      rows.add(TableRow(
        children: <Widget>[
          const SizedBox(width: 24),
          center(Text(ingredient.name,
              style: TextStyles.normal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
          center(Text(_vegStatusText(ingredient.vegetarianStatus),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          center(Text(_vegStatusText(ingredient.veganStatus),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 24),
        ],
        decoration: BoxDecoration(color: nextColor()),
      ));
      linesCount += 1;
      if (linesCount >= maxLines) {
        break;
      }
    }
    return Table(
        key: const Key('ingredients_analysis_table'),
        children: rows,
        border: TableBorder.all(color: Colors.transparent),
        columnWidths: const <int, TableColumnWidth>{
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(10),
          2: FlexColumnWidth(4),
          3: IntrinsicColumnWidth(),
          4: FlexColumnWidth(4),
          5: IntrinsicColumnWidth(),
        });
  }

  String _vegStatusText(VegStatus? vegStatus) {
    switch (vegStatus) {
      case VegStatus.positive:
        return context.strings.display_product_page_table_positive;
      case VegStatus.negative:
        return context.strings.display_product_page_table_negative;
      case VegStatus.possible:
        return context.strings.display_product_page_table_possible;
      case VegStatus.unknown: // Fallthrough
      case null:
        return context.strings.display_product_page_table_unknown;
      default:
        throw Exception('Unknown veg status: $vegStatus');
    }
  }

  void _onReportClick() {
    showDialog(
      context: context,
      builder: (context) {
        return ProductReportDialog(barcode: product.barcode, backend: backend);
      },
    );
  }

  void _showVegStatusesExplanation() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return VegStatusesExplanationDialog(vegStatusText: _vegStatusText);
      },
    );
  }

  void _showProductPhoto() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPhotoPage(
                key: const Key('product_front_image_page'),
                product: product,
                imageType: ProductImageType.FRONT)));
  }

  void _showProductIngredientsPhoto() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPhotoPage(
                key: const Key('product_ingredients_image_page'),
                product: product,
                imageType: ProductImageType.INGREDIENTS)));
  }

  void _copyIngredientsList() {
    if (product.ingredientsText != null &&
        product.ingredientsText!.trim().isNotEmpty) {
      Clipboard.setData(ClipboardData(text: product.ingredientsText ?? ''));
      showSnackBar(context.strings.global_copied_to_clipboard, context);
    }
  }

  void _copyProductName() {
    Clipboard.setData(ClipboardData(text: product.name));
    showSnackBar(context.strings.global_copied_to_clipboard, context);
  }

  void _showProductMenu() async {
    final selected =
        await showMenuPlante(target: menuButtonKey, context: context, values: [
      1
    ], children: [
      MenuItemPlante(
        title: context.strings.display_product_page_report_btn,
        description: context.strings.product_report_dialog_title,
      )
    ]);

    if (selected == 1) {
      _onReportClick();
    }
  }

  void _markOnMap() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
              requestedMode: MapPageRequestedMode.ADD_PRODUCT,
              product: product),
        ));
  }
}
