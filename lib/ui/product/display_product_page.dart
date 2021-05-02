import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/model/product.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/base/my_stateful_builder.dart';
import 'package:plante/ui/product/init_product_page.dart';

import '_product_images_helper.dart';

typedef ProductUpdatedCallback = void Function(Product updatedProduct);

class DisplayProductPage extends StatefulWidget {
  final Key? key;
  final Product _initialProduct;
  final ProductUpdatedCallback? productUpdatedCallback;

  DisplayProductPage(this._initialProduct,
      {this.key, this.productUpdatedCallback});

  @override
  _DisplayProductPageState createState() => _DisplayProductPageState(
      this._initialProduct, this.key, this.productUpdatedCallback);
}

class _DisplayProductPageState extends State<DisplayProductPage> {
  final Key? _key;
  Product _product;
  final ProductUpdatedCallback? _productUpdatedCallback;

  final _reportTextController = TextEditingController();
  bool get _reportSendAllowed => _reportTextController.text.trim().length > 3;
  bool _loading = false;

  _DisplayProductPageState(
      this._product, this._key, this._productUpdatedCallback);

  String _vegetarianStatusStr(VegStatus? vegStatus,
          {bool nullIsUnknown = true}) =>
      "${context.strings.display_product_page_whether_vegetarian}"
      "${_vegStatusToStr(vegStatus, nullIsUnknown)}";

  String _veganStatusStr(VegStatus? vegStatus, {bool nullIsUnknown = true}) =>
      "${context.strings.display_product_page_whether_vegan}"
      "${_vegStatusToStr(vegStatus, nullIsUnknown)}";

  String _vegStatusToStr(VegStatus? vegStatus, bool nullIsUnknown) {
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

  String _vegStatusSource(VegStatusSource source) {
    return "${context.strings.display_product_page_veg_status_source}"
        "${_vegStatusSourceToStr(source)}";
  }

  String _vegStatusSourceToStr(VegStatusSource source) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: [
          SizedBox(
              width: double.infinity,
              height: 200,
              child: ProductImagesHelper.productImageWidget(
                  _product, ProductImageType.FRONT)),
          Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Column(children: [
                Text(_product.name!,
                    style: Theme.of(context).textTheme.headline5),
                SizedBox(height: 20),
                _wideStartText(_vegetarianStatusStr(_product.vegetarianStatus),
                    key: "vegetarian_status"),
                if (_product.vegetarianStatusSource != null)
                  _wideStartText(
                      _vegStatusSource(_product.vegetarianStatusSource!),
                      key: "vegetarian_status_source"),
                SizedBox(height: 10),
                _wideStartText(_veganStatusStr(_product.veganStatus),
                    key: "vegan_status"),
                if (_product.veganStatusSource != null)
                  _wideStartText(_vegStatusSource(_product.veganStatusSource!),
                      key: "vegan_status_source"),
                SizedBox(height: 10),
                if (_product.vegetarianStatusSource ==
                        VegStatusSource.open_food_facts ||
                    _product.veganStatusSource ==
                        VegStatusSource.open_food_facts)
                  _atStart(OutlinedButton(
                      child: Text(context
                          .strings.display_product_page_help_with_veg_statuses),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => InitProductPage(_product,
                                      key: Key("init_product_page"),
                                      productUpdatedCallback: (product) {
                                    _productUpdatedCallback?.call(_product);
                                    setState(() {
                                      _product = product;
                                    });
                                  })),
                        );
                      })),
                SizedBox(height: 10),
                ExpandablePanel(
                  header: Column(children: [
                    SizedBox(height: 10),
                    _wideStartText(
                        context.strings.display_product_page_ingredients,
                        style: Theme.of(context).textTheme.headline6)
                  ]),
                  collapsed: Text(_product.ingredientsText.toString(),
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  expanded: Column(children: [
                    ProductImagesHelper.productImageWidget(
                        _product, ProductImageType.INGREDIENTS),
                    _wideStartText(_product.ingredientsText.toString())
                  ]),
                ),
                if (_hasIngredientsAnalysis())
                  ExpandablePanel(
                    header: Column(children: [
                      SizedBox(height: 10),
                      _wideStartText(
                          context.strings
                              .display_product_page_ingredients_analysis,
                          style: Theme.of(context).textTheme.headline6)
                    ]),
                    collapsed: Text("..."),
                    expanded: _ingredientsAnalysisTable(
                        key: "ingredients_analysis_table"),
                  ),
                OutlinedButton(
                    child: Text(context.strings.display_product_page_report),
                    onPressed: _onReportClick),
              ]))
        ]))));
  }

  Widget _wideStartText(String str, {String? key, TextStyle? style}) =>
      _atStart(Text(str, key: key != null ? Key(key) : null, style: style));

  Widget _atStart(Widget child) =>
      Container(alignment: AlignmentDirectional.centerStart, child: child);

  Widget _atEnd(Widget child) =>
      Container(alignment: AlignmentDirectional.centerEnd, child: child);

  bool _hasIngredientsAnalysis() =>
      _product.ingredientsAnalyzed != null &&
      _product.ingredientsAnalyzed!.isNotEmpty;

  Widget _ingredientsAnalysisTable({String? key}) {
    final rows = <TableRow>[];
    final ingredients = _product.ingredientsAnalyzed!;
    for (final ingredient in ingredients) {
      rows.add(TableRow(
        children: <Widget>[
          Text(ingredient.name),
          Text(_vegetarianStatusStr(ingredient.vegetarianStatus,
              nullIsUnknown: false)),
          Text(_veganStatusStr(ingredient.veganStatus, nullIsUnknown: false)),
        ],
      ));
    }
    return Table(
        key: key != null ? Key(key) : null,
        children: rows,
        border: TableBorder.all(),
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
        });
  }

  void _onReportClick() {
    Function()? reportTextListener;

    showDialog(
      context: context,
      builder: (context) {
        return MyStatefulBuilder(
          disposer: () {
            if (reportTextListener != null) {
              _reportTextController.removeListener(reportTextListener!);
            }
          },
          builder: (context, setState) {
            if (reportTextListener != null) {
              _reportTextController.removeListener(reportTextListener!);
            }
            reportTextListener = () {
              setState(() {
                // UI update
              });
            };
            _reportTextController.addListener(reportTextListener!);

            final onSendClick = () async {
              setState(() {
                _loading = true;
              });
              try {
                final result = await GetIt.I
                    .get<Backend>()
                    .sendReport(_product.barcode, _reportTextController.text);
                if (result.isOk) {
                  _reportTextController.clear();
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
                  _loading = false;
                });
              }
            };

            return AlertDialog(
              title: Row(children: [
                if (_loading) CircularProgressIndicator(),
                Text(context.strings.display_product_page_report)
              ]),
              content: TextField(
                  key: Key("report_text"),
                  maxLines: null,
                  controller: _reportTextController),
              actions: <Widget>[
                TextButton(
                    child:
                        Text(context.strings.display_product_page_report_send),
                    onPressed:
                        _reportSendAllowed && !_loading ? onSendClick : null),
              ],
            );
          },
        );
      },
    );
  }
}
