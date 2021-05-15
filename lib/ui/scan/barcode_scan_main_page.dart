import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/ui/base/components/bottom_bar_plante.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/scan/viewed_products_history_page.dart';

class BarcodeScanMainPage extends StatefulWidget {
  const BarcodeScanMainPage({Key? key}) : super(key: key);

  @override
  _BarcodeScanMainPageState createState() => _BarcodeScanMainPageState();
}

class _BarcodeScanMainPageState extends State<BarcodeScanMainPage> {
  var selectedPage = 0;
  final pageOptions = [
    BarcodeScanPage(key: const Key('barcode_scan_page')),
    const ViewedProductsHistoryPage(key: Key('viewed_products_history_page')),
  ];
  final PageController pagerController = PageController();

  @override
  Widget build(BuildContext context) {
    GetIt.I.get<LangCodeHolder>().langCode =
        Localizations.localeOf(context).languageCode;
    return Scaffold(
        body: IndexedStack(index: selectedPage, children: pageOptions),
        bottomNavigationBar: BottomBarPlante(
          svgIcons: const ['assets/barcode.svg', 'assets/history.svg'],
          selectedIcon: selectedPage,
          onIconClick: (index) {
            setState(() {
              selectedPage = index;
            });
          },
        ));
  }
}
