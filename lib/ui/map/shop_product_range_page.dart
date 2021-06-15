import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/components/animated_cross_fade_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

class ShopProductRangePage extends StatefulWidget {
  final Shop shop;
  const ShopProductRangePage._({Key? key, required this.shop})
      : super(key: key);

  @visibleForTesting
  static ShopProductRangePage createForTesting(Shop shop) {
    if (!isInTests()) {
      throw Exception('!isInTests()');
    }
    return ShopProductRangePage._(shop: shop);
  }

  static void show(
      {Key? key, required BuildContext context, required Shop shop}) {
    final args = [
      shop.toJson(),
    ];
    Navigator.restorablePush(context, _routeBuilder, arguments: args);
  }

  static Route<void> _routeBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute<void>(builder: (BuildContext context) {
      Shop shop = Shop.empty;
      if (arguments != null) {
        final args = arguments as List<dynamic>;
        shop = Shop.fromJson(args[0] as Map<dynamic, dynamic>) ?? Shop.empty;
      }
      if (shop == Shop.empty) {
        Log.e('ShopProductRangePage is created with invalid arguments or '
            'without any. Args: $arguments');
      }
      return ShopProductRangePage._(shop: shop);
    });
  }

  @override
  _ShopProductRangePageState createState() => _ShopProductRangePageState();
}

class _ShopProductRangePageState extends State<ShopProductRangePage>
    with RouteAware {
  final ShopsManager _shopsManager;
  final UserParamsController _userParamsController;
  final Backend _backend;
  final RouteObserver<ModalRoute> _routeObserver;
  bool _loading = false;
  bool _performingBackendAction = false;
  ShopProductRange? _shopProductRange;
  ShopsManagerError? _shopProductRangeLoadingError;

  _ShopProductRangePageState()
      : _shopsManager = GetIt.I.get<ShopsManager>(),
        _userParamsController = GetIt.I.get<UserParamsController>(),
        _backend = GetIt.I.get<Backend>(),
        _routeObserver = GetIt.I.get<RouteObserver<ModalRoute>>();

  @override
  void initState() {
    super.initState();
    _load();
    initializeDateFormatting();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    super.dispose();
    _routeObserver.unsubscribe(this);
  }

  @override
  void didUpdateWidget(ShopProductRangePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  @override
  void didPopNext() {
    if (ModalRoute.of(context)?.isCurrent == true) {
      // Reload!
      _load();
    }
  }

  void _load() async {
    setState(() {
      _loading = true;
      _shopProductRangeLoadingError = null;
    });
    try {
      final loadResult = await _shopsManager.fetchShopProductRange(widget.shop);
      if (loadResult.isOk) {
        _shopProductRange = loadResult.unwrap();
      } else {
        _shopProductRangeLoadingError = loadResult.unwrapErr();
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_shopProductRangeLoadingError != null) {
      if (_shopProductRangeLoadingError == ShopsManagerError.NETWORK_ERROR) {
        content = Center(
            child: Column(children: [
          Text(context.strings.global_network_error, style: TextStyles.normal),
          ButtonFilledPlante.withText(context.strings.global_try_again,
              onPressed: _load)
        ]));
      } else {
        content = Center(
            child: Text(context.strings.global_something_went_wrong,
                style: TextStyles.normal));
      }
    } else if (_shopProductRange!.products.isEmpty) {
      content = Center(
          child: Text(
              context.strings.shop_product_range_page_this_shop_has_no_product,
              style: TextStyles.normal));
    } else {
      final products = _shopProductRange!.products;
      final user = _userParamsController.cachedUserParams!;
      content = ListView(
          children: products.map((e) {
        final date = DateTime.fromMillisecondsSinceEpoch(
            _shopProductRange!.lastSeenSecs(e) * 1000);
        final dateStr = intl.DateFormat.yMMMMd(context.langCode).format(date);

        return Padding(
            key: Key('product_${e.barcode}'),
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ProductCard(
                  product: e,
                  beholder: user,
                  onTap: () {
                    _openProductPage(e);
                  }),
              Text(
                  '${context.strings.shop_product_range_page_product_last_seen_here}$dateStr'),
              Text(context
                  .strings.shop_product_range_page_have_you_seen_product_here),
              Row(children: [
                Expanded(
                    child: ButtonOutlinedPlante.withText(
                        context.strings.global_no, onPressed: () {
                  _onProductPresenceVote(e, false);
                })),
                Expanded(
                    child: ButtonOutlinedPlante.withText(
                        context.strings.global_yes, onPressed: () {
                  _onProductPresenceVote(e, true);
                }))
              ])
            ]));
      }).toList());
    }
    return Scaffold(
      body: SafeArea(
          child: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 44),
            child: Column(children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    FabPlante.closeBtnPopOnClick(
                        key: const Key('close_button')),
                    Expanded(
                        child: Text(widget.shop.name,
                            style: TextStyles.headline1)),
                  ]),
              const SizedBox(height: 28),
              SizedBox(
                  width: double.infinity,
                  child: ButtonFilledPlante.withText(
                      context.strings.shop_product_range_page_add_product,
                      onPressed: !_loading ? _onAddProductClick : null)),
            ]),
          ),
          const SizedBox(height: 24),
          Expanded(child: content)
        ]),
        Positioned.fill(
            child: AnimatedCrossFadePlante(
          crossFadeState: _performingBackendAction
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: const Color(0x70FFFFFF),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ))
      ])),
    );
  }

  void _openProductPage(Product product) {
    ProductPageWrapper.show(context, product,
        productUpdatedCallback: _onProductUpdate);
  }

  void _onProductUpdate(Product updatedProduct) {
    if (_shopProductRange == null) {
      return;
    }
    final products = _shopProductRange!.products.toList();
    final productToUpdate = products
        .indexWhere((product) => product.barcode == updatedProduct.barcode);
    if (productToUpdate == -1) {
      Log.e(
          'Updated product is not found. Product: $updatedProduct, all products: $products');
      return;
    }
    products[productToUpdate] = updatedProduct;
    _shopProductRange =
        _shopProductRange!.rebuild((e) => e.products.replace(products));
  }

  void _onProductPresenceVote(Product product, bool positive) async {
    final title = positive
        ? context.strings.shop_product_range_page_you_sure_positive_vote
        : context.strings.shop_product_range_page_you_sure_negative_vote;
    await showYesNoDialog(context, title, () {
      _performProductPresenceVote(product, positive);
    });
  }

  void _performProductPresenceVote(Product product, bool positive) async {
    setState(() {
      _performingBackendAction = true;
    });
    try {
      final result = await _backend.productPresenceVote(
          product.barcode, widget.shop.osmId, positive);
      if (result.isOk) {
        showSnackBar(context.strings.global_done_thanks, context);
        setState(() {
          // TODO(https://trello.com/c/dCDHecZS/): test
          _shopProductRange = _shopProductRange!.rebuild((e) =>
              e.productsLastSeenSecsUtc[product.barcode] =
                  DateTime.now().secondsSinceEpoch);
        });
      } else {
        if (result.unwrapErr().errorKind == BackendErrorKind.NETWORK_ERROR) {
          showSnackBar(context.strings.global_network_error, context);
        } else {
          showSnackBar(context.strings.global_something_went_wrong, context);
        }
      }
    } finally {
      setState(() {
        _performingBackendAction = false;
      });
    }
  }

  void _onAddProductClick() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                BarcodeScanPage(addProductToShop: widget.shop)));
  }
}

extension _DateTimeExt on DateTime {
  int get secondsSinceEpoch => (millisecondsSinceEpoch / 1000).round();
}
