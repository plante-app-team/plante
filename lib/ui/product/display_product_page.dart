import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/colors_plante.dart';
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
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/product/init_product_page.dart';
import 'package:plante/ui/product/product_photo_page.dart';

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

class _DisplayProductPageState extends State<DisplayProductPage> {
  Product product;
  final UserParams user;
  final ProductUpdatedCallback? productUpdatedCallback;

  final reportTextController = TextEditingController();
  final expandController = ExpandableController();
  bool get reportSendAllowed => reportTextController.text.trim().length > 3;
  bool loading = false;

  final menuButtonKey = GlobalKey();

  _DisplayProductPageState(this.product, this.productUpdatedCallback)
      : user = GetIt.I.get<UserParamsController>().cachedUserParams! {
    GetIt.I.get<ViewedProductsStorage>().addProduct(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Stack(children: [
          Column(children: [
            HeaderPlante(
              leftAction: FabPlante.backBtnPopOnClick(heroTag: 'left_action'),
              // Sized box is only for the key
              rightAction: SizedBox(
                  key: const Key('options_button'),
                  child: FabPlante.menuBtn(
                      key: menuButtonKey,
                      heroTag: 'right_action',
                      onPressed: showProductMenu)),
            ),
            Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Column(children: [
                  const SizedBox(height: 12),
                  ProductHeaderWidget(
                      key: const Key('product_header'),
                      product: product,
                      onTap: showProductPhoto),
                ])),
            const SizedBox(height: 19),
            Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(children: [
                  InkWell(
                    onTap: askForVegStatusHelp() ? onVegStatusHelpClick : null,
                    child: VegStatusDisplayed(
                        product: product,
                        user: user,
                        helpText: askForVegStatusHelp()
                            ? context.strings
                                .display_product_page_click_to_help_with_veg_statuses
                            : null,
                        onHelpClick: onVegStatusHelpClick),
                  ),
                ])),
            const SizedBox(height: 16),
            if (vegStatusHint() != null)
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
                        child: Text(vegStatusHint()!, style: TextStyles.hint),
                      ))),
            const SizedBox(height: 16),
            if (enableNewestFeatures())
              Column(children: [
                Container(
                    width: double.infinity,
                    height: 96,
                    color: ColorsPlante.primary,
                    child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('mark_on_map'),
                          overlayColor: MaterialStateProperty.all(
                              ColorsPlante.splashColor),
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
                onTap: showProductIngredientsPhoto,
                child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Column(children: [
                      SizedBox(
                          width: double.infinity,
                          child: Text(
                              context.strings.display_product_page_ingredients,
                              style: TextStyles.normalBold)),
                      const SizedBox(height: 8),
                      SizedBox(
                          width: double.infinity,
                          child: Text(product.ingredientsText!,
                              style: TextStyles.normal)),
                      const SizedBox(height: 24),
                    ]))),
            if (haveIngredientsAnalysis()) ingredientsAnalysisWidget(),
            const SizedBox(height: 16)
          ]),
        ]))));
  }

  String? vegStatusHint() {
    switch (vegStatus()) {
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

  Widget ingredientsAnalysisWidget() {
    if (product.ingredientsAnalyzed?.length == 1) {
      return ingredientsAnalysisWidgetWithLines(9999);
    }
    return ExpandablePlante(
      collapsed: ingredientsAnalysisWidgetWithLines(1),
      expanded: Column(children: [
        ingredientsAnalysisWidgetWithLines(9999),
        const SizedBox(height: 58)
      ]),
    );
  }

  Column ingredientsAnalysisWidgetWithLines(int lines) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: Row(children: [
            Text(context.strings.display_product_page_ingredients_analysis,
                style: TextStyles.normalBold),
            InfoButtonPlante(onTap: showVegStatusesExplanation)
          ])),
      const SizedBox(height: 16),
      ingredientsAnalysisTable(lines)
    ]);
  }

  bool askForVegStatusHelp() {
    return vegStatusSource() == VegStatusSource.open_food_facts;
  }

  void onVegStatusHelpClick() {
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

  VegStatus vegStatus() {
    VegStatus? status;
    if (user.eatsVeggiesOnly ?? true) {
      status = product.veganStatus;
    } else {
      status = product.vegetarianStatus;
    }
    return status ?? VegStatus.unknown;
  }

  VegStatusSource vegStatusSource() {
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

  Widget vegStatusSourceIcon(VegStatusSource vegStatusSource) {
    switch (vegStatusSource) {
      case VegStatusSource.open_food_facts:
        return SvgPicture.asset('assets/veg_status_source_auto.svg');
      case VegStatusSource.community:
        return SvgPicture.asset('assets/veg_status_source_community.svg');
      case VegStatusSource.moderator:
        return SvgPicture.asset('assets/veg_status_source_moderator.svg');
      case VegStatusSource.unknown:
        return SvgPicture.asset('assets/veg_status_source_community.svg');
      default:
        throw Exception('Unhandled veg status source: $vegStatusSource');
    }
  }

  bool haveIngredientsAnalysis() =>
      product.ingredientsAnalyzed != null &&
      product.ingredientsAnalyzed!.isNotEmpty;

  Widget ingredientsAnalysisTable(int maxLines) {
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
          center(Text(vegStatusText(ingredient.vegetarianStatus),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          center(Text(vegStatusText(ingredient.veganStatus),
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

  String vegStatusText(VegStatus? vegStatus) {
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

  void onReportClick() {
    Function()? reportTextListener;

    showDialog(
      context: context,
      builder: (context) {
        return MyStatefulBuilder(
          disposer: () {
            if (reportTextListener != null) {
              reportTextController.removeListener(reportTextListener!);
            }
          },
          builder: (context, setState) {
            if (reportTextListener != null) {
              reportTextController.removeListener(reportTextListener!);
            }
            reportTextListener = () {
              setState(() {
                // UI update
              });
            };
            reportTextController.addListener(reportTextListener!);

            final onSendClick = () async {
              setState(() {
                loading = true;
              });
              try {
                final result = await GetIt.I
                    .get<Backend>()
                    .sendReport(product.barcode, reportTextController.text);
                if (result.isOk) {
                  reportTextController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          context.strings.display_product_page_report_sent)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(context.strings.global_something_went_wrong)));
                }
              } finally {
                setState(() {
                  loading = false;
                });
              }
            };

            return DialogPlante(
              title: Text(context.strings.display_product_page_report),
              content: Column(children: [
                if (loading) const CircularProgressIndicator(),
                InputFieldMultilinePlante(
                    key: const Key('report_text'),
                    maxLines: 5,
                    controller: reportTextController),
              ]),
              actions: ButtonFilledPlante.withText(
                  context.strings.display_product_page_report_send,
                  onPressed:
                      reportSendAllowed && !loading ? onSendClick : null),
            );
          },
        );
      },
    );
  }

  void showVegStatusesExplanation() {
    final content = Table(
        children: [
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.positive)),
              const SizedBox(width: 16),
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_positive_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.negative)),
              const SizedBox(width: 16),
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_negative_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.unknown)),
              const SizedBox(width: 16),
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_unknown_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              Text(vegStatusText(VegStatus.possible)),
              const SizedBox(width: 16),
              Text(
                  context.strings
                      .display_product_page_veg_status_possible_explanation,
                  style: TextStyles.normal),
            ],
          )
        ],
        border: TableBorder.all(color: Colors.transparent),
        columnWidths: const <int, TableColumnWidth>{
          0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(1),
        });

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return DialogPlante(
          content: content,
          actions: ButtonFilledPlante.withText(
              context.strings.display_product_page_veg_status_explanations_ok,
              onPressed: () {
            Navigator.of(context).pop();
          }),
        );
      },
    );
  }

  void showProductPhoto() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPhotoPage(
                key: const Key('product_front_image_page'),
                product: product,
                imageType: ProductImageType.FRONT)));
  }

  void showProductIngredientsPhoto() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPhotoPage(
                key: const Key('product_ingredients_image_page'),
                product: product,
                imageType: ProductImageType.INGREDIENTS)));
  }

  void showProductMenu() async {
    final selected =
        await showMenuPlante(target: menuButtonKey, context: context, values: [
      1
    ], children: [
      MenuItemPlante(
        title: context.strings.display_product_page_report_btn,
        description: context.strings.display_product_page_report,
      )
    ]);

    if (selected == 1) {
      onReportClick();
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
