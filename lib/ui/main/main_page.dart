import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/bottom_bar_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/profile/profile_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/scan/viewed_products_history_page.dart';

class MainPage extends PagePlante {
  static const PAGE_NAME = 'MainPage';
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends PageStatePlante<MainPage> with RestorationMixin {
  final _mapPage = MapPage();
  final _barcodePage = BarcodeScanPage();
  final _historyPage = const ViewedProductsHistoryPage();
  final _profilePage = const ProfilePage();

  late final Map<Widget, String> _pagesIcons;
  late final UIValue<List<Widget>> _pages;
  late final _selectedPage = RestorableInt(0);
  late final UIValue<bool> _enableProfile;
  final PageController pagerController = PageController();

  _MainPageState() : super(MainPage.PAGE_NAME);

  @override
  String? get restorationId => 'main_page';

  @override
  void initState() {
    super.initState();
    _enableProfile = UIValue(false, ref);
    _pagesIcons = {
      _mapPage: 'assets/bottom_bar_map.svg',
      _barcodePage: 'assets/bottom_bar_barcode.svg',
      _historyPage: 'assets/bottom_bar_history.svg',
      _profilePage: 'assets/bottom_bar_profile.svg',
    };
    _pages = UIValue([
      _mapPage,
      _barcodePage,
      _historyPage,
    ], ref);

    () async {
      _enableProfile.setValue(await enableNewestFeatures());
      if (await enableNewestFeatures()) {
        _pages.setValue([
          _mapPage,
          _barcodePage,
          _profilePage,
        ]);
      }
    }.call();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedPage, 'selected_page');
  }

  @override
  void dispose() {
    _selectedPage.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        body: WillPopScope(
            onWillPop: () async {
              if (_selectedPage.value == 0) {
                return true;
              } else {
                setState(() {
                  _selectedPage.value = 0;
                });
                return false;
              }
            },
            child: IndexedStack(
                index: _selectedPage.value, children: _pages.watch(ref))),
        bottomNavigationBar: _bottomBar());
  }

  Widget _bottomBar() {
    return consumer((ref) {
      final enableProfile = _enableProfile.watch(ref);
      final pagesBottomButtons = _pages.watch(ref);
      final children = [
        ...pagesBottomButtons.map((e) {
          final index = pagesBottomButtons.indexOf(e);
          return IconButton(
              onPressed: () {
                setState(() {
                  _selectedPage.value = index;
                });
              },
              icon: SvgPicture.asset(_pagesIcons[e]!,
                  color: index == _selectedPage.value
                      ? ColorsPlante.primary
                      : ColorsPlante.grey));
        }).toList(),
        if (enableProfile)
          FabPlante(
            svgAsset: 'assets/bottom_bar_plus.svg',
            shadow: const BoxShadow(
              color: Color(0x261E2030),
              spreadRadius: 0,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
            onPressed: () {
              showSnackBar('Hello there', context);
            },
          ),
      ];
      return BottomBarPlante(children: children);
    });
  }
}
