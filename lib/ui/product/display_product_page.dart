import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/moderator_choice_reason.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/expandable_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/info_button_plante.dart';
import 'package:plante/ui/base/components/menu_item_plante.dart';
import 'package:plante/ui/base/components/veg_status_displayed.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/popup/popup_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/product/_veg_status_warning.dart';
import 'package:plante/ui/product/help_with_veg_status_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/moderator_comment_dialog.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';
import 'package:plante/ui/product/product_photo_page.dart';
import 'package:plante/ui/product/product_report_dialog.dart';
import 'package:plante/ui/product/veg_statuses_explanation_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: always_use_package_imports
import 'product_header_widget.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class DisplayProductPage extends PagePlante {
  final Product _initialProduct;
  final ProductUpdatedCallback? productUpdatedCallback;

  const DisplayProductPage(this._initialProduct,
      {Key? key, this.productUpdatedCallback})
      : super(key: key);

  @override
  _DisplayProductPageState createState() =>
      _DisplayProductPageState(_initialProduct, productUpdatedCallback);
}

class _DisplayProductPageState extends PageStatePlante<DisplayProductPage>
    implements UserLangsManagerObserver {
  Product _product;
  final Backend _backend;
  final UserParams _user;
  final UserLangsManager _userLangsManager;
  List<LangCode>? _userLangs;
  final ProductUpdatedCallback? _productUpdatedCallback;

  final expandController = ExpandableController();
  bool loading = false;

  final menuButtonKey = GlobalKey();

  _DisplayProductPageState(this._product, this._productUpdatedCallback)
      : _backend = GetIt.I.get<Backend>(),
        _user = GetIt.I.get<UserParamsController>().cachedUserParams!,
        _userLangsManager = GetIt.I.get<UserLangsManager>(),
        super('DisplayProductPage') {
    GetIt.I.get<ViewedProductsStorage>().addProduct(_product);
    _userLangsManager.getUserLangs().then(onUserLangsChange);
    _userLangsManager.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    _userLangsManager.removeObserver(this);
  }

  @override
  void onUserLangsChange(UserLangs userLangs) {
    setState(() {
      final oldUserLangs = _userLangs;
      _userLangs = userLangs.langs.toList();
      if (oldUserLangs == null) {
        if (_isProductInForeignLang()) {
          analytics.sendEvent('product_displayed_in_foreign_lang');
        } else {
          analytics.sendEvent('product_displayed_in_user_lang');
        }
      }
    });
  }

  bool _isProductInForeignLang() {
    return _userLangs != null &&
        !ProductPageWrapper.isProductFilledEnoughForDisplayInLangs(
            _product, _userLangs!);
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
              leftAction: const FabPlante.backBtnPopOnClick(
                  key: Key('back_button'), heroTag: 'left_action'),
              // Sized box is only for the key
              rightAction: SizedBox(
                  key: const Key('options_button'),
                  child: FabPlante.menuBtn(
                      key: menuButtonKey,
                      heroTag: 'right_action',
                      onPressed: _showProductMenu)),
            ),
            if (_isProductInForeignLang())
              Container(
                color: ColorsPlante.lightGrey,
                padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 16, bottom: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          context.strings
                              .display_product_page_no_info_in_your_langs,
                          style: TextStyles.smallBoldGreen),
                      const SizedBox(height: 8),
                      SizedBox(
                          width: double.infinity,
                          child: ButtonFilledPlante.withText(
                              context.strings
                                  .display_product_page_add_info_in_your_langs,
                              onPressed: _onAddProductInfoClick))
                    ]),
              ),
            Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Column(children: [
                  const SizedBox(height: 12),
                  ProductHeaderWidget(
                      key: const Key('product_header'),
                      product: _product,
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
                        product: _product,
                        user: _user,
                        onVegStatusClick: _onVegStatusSourceClickCallback(),
                        helpText: _askForVegStatusHelp()
                            ? context.strings
                                .display_product_page_click_to_help_with_veg_statuses
                            : null,
                        onHelpClick: _onVegStatusHelpClick),
                  ),
                ])),
            const SizedBox(height: 16),
            ..._veganStatusWarnings().map((e) => Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                child: VegStatusWarning(
                  showWarningImage: true,
                  color: ColorsPlante.amber,
                  text: e,
                  style: TextStyles.hint
                      .copyWith(color: ColorsPlante.mainTextBlack),
                ))),
            if (_vegStatusHint() != null)
              Padding(
                  key: const Key('veg_status_hint'),
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  child: VegStatusWarning(
                    color: ColorsPlante.lightGrey,
                    text: _vegStatusHint()!,
                    style: TextStyles.hint,
                  )),
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
                      if (_product.ingredientsText != null)
                        SizedBox(
                            key: const Key('product_ingredients_text'),
                            width: double.infinity,
                            child: Text(_product.ingredientsText!,
                                style: TextStyles.normal)),
                      if (_product.ingredientsText == null)
                        ProductHeaderWidget(
                            key: const Key('product_ingredients_photo'),
                            product: _product,
                            imageType: ProductImageType.INGREDIENTS,
                            onTap: _showProductIngredientsPhoto),
                      const SizedBox(height: 24),
                    ]))),
            if (_haveIngredientsAnalysis()) _ingredientsAnalysisWidget(),
            const SizedBox(height: 16)
          ]),
        ]))));
  }

  void _onAddProductInfoClick() {
    analytics.sendEvent('display_product_page_clicked_add_info_in_lang');
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              InitProductPage(_product, key: const Key('init_product_page'),
                  productUpdatedCallback: (product) {
                _productUpdatedCallback?.call(product);
                setState(() {
                  _product = product;
                });
              })),
    );
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
    if (_product.ingredientsAnalyzed?.length == 1) {
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
    if (_vegStatusSource() != VegStatusSource.moderator) {
      return _vegStatusSource() == VegStatusSource.open_food_facts ||
          _vegStatus() == VegStatus.unknown;
    }
    return false;
  }

  Iterable<String> _veganStatusWarnings() {
    return _product.moderatorVeganChoiceReasons
        .where((e) => e.printWarningOnProduct)
        .map((e) => e.localize(context));
  }

  void _onVegStatusHelpClick() {
    analytics.sendEvent('help_with_vegan_statuses_started');
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => HelpWithVegStatusPage(_product,
                  key: const Key('help_with_veg_status_page'),
                  productUpdatedCallback: (product) {
                _productUpdatedCallback?.call(product);
                setState(() {
                  _product = product;
                });
              })),
    );
  }

  VegStatus _vegStatus() {
    return _product.veganStatus ?? VegStatus.unknown;
  }

  VegStatusSource _vegStatusSource() {
    VegStatusSource? source = _product.veganStatusSource;
    if (source == null || source == VegStatusSource.unknown) {
      source = VegStatusSource.community;
    }
    return source;
  }

  VoidCallback? _onVegStatusSourceClickCallback() {
    if (_vegStatusSource() != VegStatusSource.moderator ||
        _product.moderatorVeganChoiceReasons.isEmpty) {
      return null;
    }
    return () {
      _onVegStatusSourceTextClick(context);
    };
  }

  void _onVegStatusSourceTextClick(BuildContext context) {
    analytics.sendEvent('moderator_comment_dialog_shown');
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ModeratorCommentDialog(
              user: _user,
              product: _product,
              onSourceUrlClick: (url) {
                analytics.sendEvent('moderator_comment_source_url_click');
                launch(url);
              });
        });
  }

  bool _haveIngredientsAnalysis() =>
      _product.ingredientsAnalyzed != null &&
      _product.ingredientsAnalyzed!.isNotEmpty;

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
      center(Text(context.strings.display_product_page_table_column3,
          textAlign: TextAlign.center, style: TextStyles.normalBold)),
      const SizedBox(width: 24),
    ], decoration: BoxDecoration(color: nextColor())));
    final ingredients = _product.ingredientsAnalyzed!;
    var linesCount = 0;
    for (final ingredient in ingredients) {
      rows.add(TableRow(
        children: <Widget>[
          const SizedBox(width: 24),
          center(Text(ingredient.cleanName(),
              style: TextStyles.normal,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
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
          2: FlexColumnWidth(6),
          3: IntrinsicColumnWidth(),
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
        return ProductReportDialog(
            barcode: _product.barcode, backend: _backend);
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
                product: _product,
                imageType: ProductImageType.FRONT)));
  }

  void _showProductIngredientsPhoto() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPhotoPage(
                key: const Key('product_ingredients_image_page'),
                product: _product,
                imageType: ProductImageType.INGREDIENTS)));
  }

  void _copyIngredientsList() {
    if (_product.ingredientsText != null &&
        _product.ingredientsText!.trim().isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _product.ingredientsText ?? ''));
      showSnackBar(context.strings.global_copied_to_clipboard, context);
    }
  }

  void _copyProductName() {
    Clipboard.setData(ClipboardData(text: _product.name));
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
    if (_product.veganStatus == VegStatus.negative) {
      showSnackBar(
          context.strings.display_product_page_adding_non_vegan_product,
          context);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapPage(
                requestedMode: MapPageRequestedMode.ADD_PRODUCT,
                product: _product),
          ));
    }
  }
}
