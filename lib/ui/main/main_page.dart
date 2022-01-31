import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/bottom_bar_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/popup/popup_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/profile/profile_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

class MainPage extends PagePlante {
  static const PAGE_NAME = 'MainPage';
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends PageStatePlante<MainPage> with RestorationMixin {
  final _mapPageController = MapPageController();
  late final _mapPage =
      MapPage(key: const Key('main_map_page'), controller: _mapPageController);
  final _barcodePage =
      BarcodeScanPage(key: const Key('main_barcode_scan_page'));
  final _profilePage = ProfilePage(key: const Key('main_profile_page'));

  final _plusButtonKey = GlobalKey();

  late final Map<Widget, String> _pagesIcons;
  late final Map<Widget, Key> _pagesButtonsKeys;
  late final UIValue<List<Widget>> _pages;
  late final _selectedPage = RestorableInt(0);
  final PageController pagerController = PageController();

  _MainPageState() : super(MainPage.PAGE_NAME);

  @override
  String? get restorationId => 'main_page';

  @override
  void initState() {
    super.initState();
    _pagesIcons = {
      _mapPage: 'assets/bottom_bar_map.svg',
      _barcodePage: 'assets/bottom_bar_barcode.svg',
      _profilePage: 'assets/bottom_bar_profile.svg',
    };
    _pagesButtonsKeys = {
      _mapPage: const Key('bottom_bar_map'),
      _barcodePage: const Key('bottom_bar_barcode'),
      _profilePage: const Key('bottom_bar_profile'),
    };
    _pages = UIValue([
      _mapPage,
      _barcodePage,
      _profilePage,
    ], ref);
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
                  _switchPageTo(pageIndex: 0);
                });
                return false;
              }
            },
            child: IndexedStack(
                key: const Key('main_pages_stack'),
                index: _selectedPage.value,
                children: _pages.watch(ref))),
        bottomNavigationBar: _bottomBar());
  }

  Widget _bottomBar() {
    return consumer((ref) {
      final pages = _pages.watch(ref);
      final children = [
        ...pages.map((page) {
          final index = pages.indexOf(page);
          return IconButton(
              key: _pagesButtonsKeys[page],
              onPressed: () {
                _switchPageTo(pageIndex: index);
              },
              icon: SvgPicture.asset(_pagesIcons[page]!,
                  color: index == _selectedPage.value
                      ? ColorsPlante.primary
                      : ColorsPlante.grey));
        }).toList(),
        Container(
            key: const Key('bottom_bar_plus_fab'),
            child: FabPlante(
              key: _plusButtonKey,
              svgAsset: 'assets/bottom_bar_plus.svg',
              shadow: const BoxShadow(
                color: Color(0x261E2030),
                spreadRadius: 0,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
              onPressed: _onPlusClick,
            )),
      ];
      return BottomBarPlante(children: children);
    });
  }

  void _onPlusClick() async {
    final selected = await showMenuPlante(
        target: _plusButtonKey,
        context: context,
        position: PlantePopupPosition.ABOVE_TARGET,
        offsetFromTarget: 21,
        values: [
          context.strings.main_page_add_product,
          context.strings.main_page_add_shop
        ],
        children: [
          Align(
              alignment: Alignment.centerRight,
              child: Text(context.strings.main_page_add_product,
                  style: TextStyles.headline2)),
          Align(
              alignment: Alignment.centerRight,
              child: Text(context.strings.main_page_add_shop,
                  style: TextStyles.headline2))
        ]);
    if (selected == context.strings.main_page_add_product) {
      _onAddProductClick();
    } else if (selected == context.strings.main_page_add_shop) {
      _onAddStoreClick();
    } else if (selected != null) {
      throw Exception('A menu item is not handled: $selected');
    }
  }

  void _onAddProductClick() {
    final switched = _switchPageTo(page: _barcodePage);
    if (!switched) {
      showSnackBar(context.strings.main_page_add_product_hint, context);
    }
  }

  bool _switchPageTo({Widget? page, int? pageIndex}) {
    pageIndex ??= _pages.cachedVal.indexOf(page!);
    page ??= _pages.cachedVal[pageIndex];
    if (pageIndex != _selectedPage.value) {
      setState(() {
        _selectedPage.value = _pages.cachedVal.indexOf(page!);
      });
      if (page != _mapPage) {
        _mapPageController.switchToDefaultMode();
      }
      return true;
    } else {
      return false;
    }
  }

  void _onAddStoreClick() {
    _switchPageTo(page: _mapPage);
    _mapPageController.startShopCreation();
  }
}
