import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/dialog_plante.dart';
import 'package:plante/model/product.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/info_button_plante.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/my_stateful_builder.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/product/init_product_page.dart';

import '_product_images_helper.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class DisplayProductPage extends StatefulWidget {
  final Product _initialProduct;
  final ProductUpdatedCallback? productUpdatedCallback;

  DisplayProductPage(this._initialProduct,
      {Key? key, this.productUpdatedCallback})
      : super(key: key);

  @override
  _DisplayProductPageState createState() => _DisplayProductPageState(
      this._initialProduct, this.productUpdatedCallback);
}

class _DisplayProductPageState extends State<DisplayProductPage> {
  Product product;
  final ProductUpdatedCallback? productUpdatedCallback;

  final reportTextController = TextEditingController();
  final expandController = ExpandableController();
  bool expanded = false;
  bool get reportSendAllowed => reportTextController.text.trim().length > 3;
  bool loading = false;

  _DisplayProductPageState(this.product, this.productUpdatedCallback);

  @override
  void initState() {
    super.initState();
    expandController.addListener(() {
      setState(() {
        expanded = expandController.expanded;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Stack(children: [
          Column(children: [
            SizedBox(height: 45),
            SizedBox(
                width: double.infinity,
                child: Text(
                  context.strings.global_app_name,
                  style: TextStyles.branding,
                  textAlign: TextAlign.center,
                )),
            SizedBox(height: 24),
            SizedBox(
                child: ProductImagesHelper.productImageWidget(
                    product, ProductImageType.FRONT)),
            Container(
                padding: EdgeInsets.only(left: 24, right: 24),
                child: Column(children: [
                  SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: Text(product.name!, style: TextStyles.headline1)),
                  SizedBox(height: 24),
                  if (product.brands != null && product.brands!.isNotEmpty)
                    Column(children: [
                      Row(children: [
                        Text(context.strings.display_product_page_brand,
                            style: TextStyles.normalBold),
                        Text(product.brands!.join(", "),
                            style: TextStyles.normal)
                      ]),
                      SizedBox(height: 21),
                    ]),
                  Row(children: [
                    Text(context.strings.display_product_page_veg_status,
                        style: TextStyles.normalBold),
                    InfoButtonPlante(onTap: showVegStatusesExplanation)
                  ]),
                  // SizedBox(height: 8),
                  Row(children: [
                    Text(context.strings.display_product_page_whether_vegan,
                        style: TextStyles.normal),
                    vegStatusIcon(product.veganStatus),
                    Text(" ", style: TextStyles.normal),
                    Text(vegStatusToStr(product.veganStatus),
                        key: Key("vegan_status"), style: TextStyles.normal),
                  ]),
                  Row(children: [
                    Text(
                        context.strings.display_product_page_whether_vegetarian,
                        style: TextStyles.normal),
                    vegStatusIcon(product.vegetarianStatus),
                    Text(" ", style: TextStyles.normal),
                    Text(vegStatusToStr(product.vegetarianStatus),
                        key: Key("vegetarian_status"),
                        style: TextStyles.normal),
                  ]),
                  InkWell(
                    child: Column(children: [
                      Row(children: [
                        Text(
                            context
                                .strings.display_product_page_veg_status_source,
                            style: TextStyles.normal),
                        vegStatusSourceIcon(vegStatusSourceOf(product)),
                        Text(" ", style: TextStyles.normal),
                        Text(vegStatusSourceToStr(vegStatusSourceOf(product)),
                            key: Key("veg_status_source"),
                            style: TextStyles.normal),
                      ]),
                      if (askForVegStatusHelp(product))
                        SizedBox(
                            width: double.infinity,
                            child: Text(
                                context.strings
                                    .display_product_page_click_to_help_with_veg_statuses,
                                style: TextStyles.normal))
                    ]),
                    onTap: askForVegStatusHelp(product)
                        ? onVegStatusHelpClick
                        : null,
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: Text(
                          context.strings.display_product_page_ingredients,
                          style: TextStyles.normalBold)),
                  SizedBox(height: 8),
                  SizedBox(
                      width: double.infinity,
                      child: Text(product.ingredientsText!,
                          style: TextStyles.normal)),
                  SizedBox(height: 24),
                ])),
            if (haveIngredientsAnalysis())
              Column(children: [
                Padding(
                    padding: EdgeInsets.only(left: 24, right: 24),
                    child: Row(children: [
                      Text(
                          context.strings
                              .display_product_page_ingredients_analysis,
                          style: TextStyles.normalBold),
                      InfoButtonPlante(onTap: showVegStatusesExplanation)
                    ])),
                SizedBox(height: 16),
                ingredientsAnalysisTable()
              ]),
            SizedBox(height: 16),
            InkWell(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SvgPicture.asset("assets/report.svg"),
                  SizedBox(width: 16),
                  Text(context.strings.display_product_page_report_btn,
                      style: TextStyles.normal),
                  SizedBox(width: 16),
                  // Invisible SVG for symmetry
                  SvgPicture.asset("assets/report.svg",
                      color: Colors.transparent),
                ]),
              ),
              onTap: onReportClick,
            )
          ]),
          Column(children: [
            SizedBox(height: 37),
            Row(children: [
              SizedBox(width: 20),
              _IconButton(
                  svg: "assets/stepper_back.svg",
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ])
          ])
        ]))));
  }

  String vegStatusToStr(VegStatus? vegStatus, [bool nullIsUnknown = true]) {
    if (vegStatus == null) {
      if (nullIsUnknown) {
        vegStatus = VegStatus.unknown;
      } else {
        return "-";
      }
    }
    switch (vegStatus) {
      case VegStatus.positive:
        return context.strings.display_product_page_veg_status_positive;
      case VegStatus.negative:
        return context.strings.display_product_page_veg_status_negative;
      case VegStatus.possible:
        return context.strings.display_product_page_veg_status_possible;
      case VegStatus.unknown:
        return context.strings.display_product_page_veg_status_unknown;
      default:
        throw StateError("Unhandled veg status element: $vegStatus");
    }
  }

  String vegStatusSourceToStr(VegStatusSource source) {
    switch (source) {
      case VegStatusSource.community:
        return context.strings.display_product_page_veg_status_source_community;
      case VegStatusSource.open_food_facts:
        return context.strings.display_product_page_veg_status_source_off;
      case VegStatusSource.moderator:
        return context.strings.display_product_page_veg_status_source_moderator;
      default:
        throw StateError("Unhandled veg status source element: $source");
    }
  }

  Widget vegStatusIcon(VegStatus? vegStatus) {
    if (vegStatus == null) {
      vegStatus = VegStatus.unknown;
    }
    final icon;
    switch (vegStatus) {
      case VegStatus.positive:
        icon = SvgPicture.asset("assets/veg_status_positive.svg");
        break;
      case VegStatus.negative:
        icon = SvgPicture.asset("assets/veg_status_negative.svg");
        break;
      case VegStatus.possible:
        icon = SvgPicture.asset("assets/veg_status_possible.svg");
        break;
      case VegStatus.unknown:
        icon = SvgPicture.asset("assets/veg_status_unknown.svg");
        break;
      default:
        throw Exception("Unhandled veg status: $vegStatus");
    }
    return SizedBox(width: 24, height: 24, child: icon);
  }

  bool askForVegStatusHelp(Product product) {
    return vegStatusSourceOf(product) == VegStatusSource.open_food_facts;
  }

  void onVegStatusHelpClick() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InitProductPage(product,
                  key: Key("init_product_page"),
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

  VegStatusSource vegStatusSourceOf(Product product) {
    var veganSource = product.veganStatusSource;
    var vegetarianSource = product.vegetarianStatusSource;
    if (veganSource == null || veganSource == VegStatusSource.unknown) {
      veganSource = VegStatusSource.community;
    }
    if (vegetarianSource == null ||
        vegetarianSource == VegStatusSource.unknown) {
      vegetarianSource = VegStatusSource.community;
    }
    // Return veg status source with worst priority
    return veganSource.priority < vegetarianSource.priority
        ? veganSource
        : vegetarianSource;
  }

  Widget vegStatusSourceIcon(VegStatusSource vegStatusSource) {
    switch (vegStatusSource) {
      case VegStatusSource.open_food_facts:
        return SvgPicture.asset("assets/veg_status_source_auto.svg");
      case VegStatusSource.community:
        return SvgPicture.asset("assets/veg_status_source_community.svg");
      case VegStatusSource.moderator:
        return SvgPicture.asset("assets/veg_status_source_moderator.svg");
      case VegStatusSource.unknown:
        return SvgPicture.asset("assets/veg_status_source_community.svg");
      default:
        throw Exception("Unhandled veg status source: $vegStatusSource");
    }
  }

  bool haveIngredientsAnalysis() =>
      product.ingredientsAnalyzed != null &&
      product.ingredientsAnalyzed!.isNotEmpty;

  Widget ingredientsAnalysisTable() {
    final rows = <TableRow>[];
    final rowHeight = 30.0;

    final colorGrey = Color(0xFFF6F7FA);
    final colorWhite = Colors.white;
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
      SizedBox(width: 24),
      center(Text(context.strings.display_product_page_table_column1,
          style: TextStyles.normalBold)),
      center(Text(context.strings.display_product_page_table_column2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.normalBold)),
      SizedBox(width: 12),
      center(Text(context.strings.display_product_page_table_column3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.normalBold)),
      SizedBox(width: 24),
    ], decoration: BoxDecoration(color: nextColor())));
    final ingredients = product.ingredientsAnalyzed!;
    for (final ingredient in ingredients) {
      rows.add(TableRow(
        children: <Widget>[
          SizedBox(width: 24),
          center(Text(ingredient.name, style: TextStyles.normal)),
          center(vegStatusIcon(ingredient.vegetarianStatus)),
          SizedBox(width: 12),
          center(vegStatusIcon(ingredient.veganStatus)),
          SizedBox(width: 24),
        ],
        decoration: BoxDecoration(color: nextColor()),
      ));
    }
    return Table(
        key: Key("ingredients_analysis_table"),
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
                if (loading) CircularProgressIndicator(),
                InputFieldMultilinePlante(
                    key: Key("report_text"),
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
              vegStatusIcon(VegStatus.positive),
              SizedBox(width: 16),
              Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_positive_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              vegStatusIcon(VegStatus.negative),
              SizedBox(width: 16),
              Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_negative_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              vegStatusIcon(VegStatus.unknown),
              SizedBox(width: 16),
              Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                      context.strings
                          .display_product_page_veg_status_unknown_explanation,
                      style: TextStyles.normal)),
            ],
          ),
          TableRow(
            children: <Widget>[
              vegStatusIcon(VegStatus.possible),
              SizedBox(width: 16),
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
}

class _IconButton extends StatelessWidget {
  final String svg;
  final dynamic Function() onPressed;

  const _IconButton({Key? key, required this.svg, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        child: IconButton(icon: SvgPicture.asset(svg), onPressed: onPressed));
  }
}
