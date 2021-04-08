import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/model/product.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/model/veg_status.dart';
import 'package:untitled_vegan_app/model/veg_status_source.dart';

import '_product_images_helper.dart';

class DisplayProductPage extends StatefulWidget {
  final Key? key;
  final Product _initialProduct;

  DisplayProductPage(this._initialProduct, {this.key});

  @override
  _DisplayProductPageState createState() =>
      _DisplayProductPageState(this._initialProduct, this.key);
}

class _DisplayProductPageState extends State<DisplayProductPage> {
  final Key? _key;
  final Product _product;

  String _vegetarianStatusStr(VegStatus? vegStatus, {bool nullIsUnknown = true}) =>
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

  _DisplayProductPageState(this._product, this._key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        body: SafeArea(child: SingleChildScrollView(child: Column(
          children: [
            SizedBox(
                width: double.infinity,
                height: 200,
                child: ProductImagesHelper.productImageWidget(
                    _product, ProductImageType.FRONT)),
            Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(children: [
                  Text(
                      _product.name!,
                      style: Theme.of(context).textTheme.headline5),

                  SizedBox(height: 20),

                  _wideStartText(
                      _vegetarianStatusStr(_product.vegetarianStatus),
                      key: "vegetarian_status"),
                  if (_product.vegetarianStatusSource != null)
                    _wideStartText(
                        _vegStatusSource(_product.vegetarianStatusSource!),
                        key: "vegetarian_status_source"),

                  SizedBox(height: 10),

                  _wideStartText(
                      _veganStatusStr(_product.veganStatus),
                      key: "vegan_status"),
                  if (_product.veganStatusSource != null)
                    _wideStartText(
                        _vegStatusSource(_product.veganStatusSource!),
                        key: "vegan_status_source"),

                  SizedBox(height: 10),

                  ExpandablePanel(
                    header: Column(children: [
                      SizedBox(height: 10),
                      _wideStartText(
                          context.strings.display_product_page_ingredients,
                          style: Theme.of(context).textTheme.headline6)
                    ]),
                    collapsed: Text(_product.ingredientsText.toString(), softWrap: true, maxLines: 1, overflow: TextOverflow.ellipsis),
                    expanded: Column(children: [
                      ProductImagesHelper.productImageWidget(
                          _product, ProductImageType.INGREDIENTS),
                      _wideStartText(_product.ingredientsText.toString())
                    ]),
                  ),

                  if (_hasIngredientsAnalysis()) ExpandablePanel(
                    header: Column(children: [
                      SizedBox(height: 10),
                      _wideStartText(
                          context.strings.display_product_page_ingredients_analysis,
                          style: Theme.of(context).textTheme.headline6)
                    ]),
                    collapsed: Text("..."),
                    expanded: _ingredientsAnalysisTable(key: "ingredients_analysis_table"),
                  ),
                ]))
          ]))));
  }

  Widget _wideStartText(String str, {String? key, TextStyle? style}) =>
      Container(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
            str,
            key: key != null ? Key(key) : null,
            style: style));

  bool _hasIngredientsAnalysis() =>
      _product.ingredientsAnalyzed != null
          && _product.ingredientsAnalyzed!.isNotEmpty;

  Widget _ingredientsAnalysisTable({String? key}) {
    final rows = <TableRow>[];
    final ingredients = _product.ingredientsAnalyzed!;
    for (final ingredient in ingredients) {
      rows.add(TableRow(
        children: <Widget>[
          Text(ingredient.name),
          Text(_vegetarianStatusStr(ingredient.vegetarianStatus, nullIsUnknown: false)),
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
}
