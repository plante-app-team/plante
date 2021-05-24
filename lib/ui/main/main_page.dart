import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/components/bottom_bar_plante.dart';
import 'package:plante/ui/base/lang_code_holder.dart';
import 'package:plante/ui/main/map/map_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/scan/viewed_products_history_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var selectedPage = 0;
  final pageOptions = [
    if (enableNewestFeatures()) MapPage(),
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
          svgIcons: [
            if (enableNewestFeatures()) 'assets/report.svg',
            'assets/barcode.svg',
            'assets/history.svg'],
          selectedIcon: selectedPage,
          onIconClick: (index) {
            setState(() {
              selectedPage = index;
            });
          },
        ));
  }
}
