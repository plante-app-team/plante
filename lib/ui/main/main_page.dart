import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/ui/base/components/bottom_bar_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/scan/viewed_products_history_page.dart';

class MainPage extends StatefulWidget {
  static const PAGE_NAME = 'MainPage';
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends PageStatePlante<MainPage> with RestorationMixin {
  final selectedPage = RestorableInt(0);
  final pageOptions = [
    MapPage(),
    BarcodeScanPage(key: const Key('barcode_scan_page')),
    const ViewedProductsHistoryPage(key: Key('viewed_products_history_page')),
  ];
  final PageController pagerController = PageController();

  _MainPageState() : super(MainPage.PAGE_NAME);

  @override
  String? get restorationId => 'main_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(selectedPage, 'selected_page');
  }

  @override
  void dispose() {
    selectedPage.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        body: WillPopScope(
            onWillPop: () async {
              if (selectedPage.value == 0) {
                return true;
              } else {
                setState(() {
                  selectedPage.value = 0;
                });
                return false;
              }
            },
            child:
                IndexedStack(index: selectedPage.value, children: pageOptions)),
        bottomNavigationBar: BottomBarPlante(
          svgIcons: const [
            'assets/marker_abstract.svg',
            'assets/barcode.svg',
            'assets/history.svg'
          ],
          selectedIcon: selectedPage.value,
          onIconClick: (index) {
            setState(() {
              selectedPage.value = index;
            });
          },
        ));
  }
}
