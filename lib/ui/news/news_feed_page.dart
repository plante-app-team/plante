import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/outside/news/news_piece.dart';
import 'package:plante/outside/news/news_piece_product_at_shop.dart';
import 'package:plante/outside/news/news_piece_type.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/address_widget.dart';
import 'package:plante/ui/base/components/animated_list_simple_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/licence_label.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/news/news_feed_page_model.dart';
import 'package:plante/ui/product/product_header_widget.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

class NewsFeedPage extends PagePlante {
  static const _DEFAULT_NEWS_LIFETIME_SECS = 60 * 6; // 5 minutes

  final int newsLifetimeSecs;

  const NewsFeedPage(
      {Key? key, this.newsLifetimeSecs = _DEFAULT_NEWS_LIFETIME_SECS})
      : super(key: key);

  @override
  _NewsFeedPageState createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends PageStatePlante<NewsFeedPage> {
  late final _model = NewsFeedPageModel(
    GetIt.I.get<NewsFeedManager>(),
    GetIt.I.get<ProductsObtainer>(),
    GetIt.I.get<ShopsManager>(),
    uiValuesFactory,
  );

  late final _uiAddressesObtainer =
      UiListAddressesObtainer<Shop>(GetIt.I.get<AddressObtainer>());

  final _visibleShops = <Shop>{};
  late final _loadingByPullToRefresh = UIValue(false, ref);

  late final _firstLoadStarted = UIValue(false, ref);

  _NewsFeedPageState() : super('PageStatePlante');

  @override
  void initState() {
    super.initState();
    _model.setNewsLifetimeSecs(widget.newsLifetimeSecs);
    _model.loading.callOnChanges((loading) {
      if (loading) {
        _firstLoadStarted.setValue(true);
      }
    });
  }

  @override
  void didUpdateWidget(NewsFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _model.setNewsLifetimeSecs(widget.newsLifetimeSecs);
  }

  @override
  Widget buildPage(BuildContext context) {
    final content = Stack(children: [
      consumer((ref) {
        final newsWidgets = _newsPiecesWidgets(_model.newsPieces.watch(ref));
        return RefreshIndicator(
            onRefresh: () async {
              _loadingByPullToRefresh.setValue(true);
              await _model.reloadNews();
              _loadingByPullToRefresh.setValue(false);
            },
            child: AnimatedListSimplePlante(
              key: const Key('news_pieces_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 21),
                  child: Text(context.strings.news_feed_page_new_events_title,
                      style: TextStyles.newsTitle),
                ),
                ...newsWidgets,
                if (_model.newsPieces.watch(ref).isNotEmpty)
                  _loadingOrErrorOrNothing(fillSpace: false),
              ],
            ));
      }),
      _loadingOrErrorOrNothing(fillSpace: true)
    ]);
    return Scaffold(
        backgroundColor: ColorsPlante.lightGrey,
        body: SafeArea(
            child: VisibilityDetectorPlante(
                keyStr: 'UserProductsWidget_visibilityDetector',
                onVisibilityChanged: (visible, _) async {
                  if (visible) {
                    _model.onPageBecameVisible();
                  }
                },
                child: content)));
  }

  Widget _loadingOrErrorOrNothing({required bool fillSpace}) {
    final makeStack = (Widget child) {
      return Stack(children: [
        Container(color: Colors.white.withOpacity(0.5)),
        child,
      ]);
    };
    return consumer((ref) {
      if (_model.loading.watch(ref)) {
        if (_loadingByPullToRefresh.watch(ref)) {
          return const SizedBox();
        }
        const result = _LoadingWidget();
        return fillSpace ? makeStack(result) : result;
      }
      final error = _model.lastError.watch(ref);
      if (error != null) {
        final result =
            _ErrorWidget(error: error, onRetryClick: _model.maybeLoadNextNews);
        return fillSpace ? makeStack(result) : result;
      }
      return const SizedBox();
    });
  }

  List<Widget> _newsPiecesWidgets(List<NewsPiece> newsPieces) {
    // NOTE: we don't have ordered shops, so we use them
    // in an unordered state.
    final allLoadedShops = _model.getAllLoadedShops().toList();
    final widgets = <Widget>[];
    for (final newsPiece in newsPieces) {
      final Widget widget;
      switch (newsPiece.type) {
        case NewsPieceType.UNKNOWN:
          widget = const SizedBox();
          break;
        case NewsPieceType.PRODUCT_AT_SHOP:
          final typedData = newsPiece.typedData as NewsPieceProductAtShop;
          final product = _model.getProductWith(typedData.barcode);
          final shop = _model.getShopWith(typedData.shopUID);
          if (product == null || shop == null) {
            widget = const SizedBox();
            break;
          }
          widget = VisibilityDetectorPlante(
              keyStr: 'shop_${shop.osmUID}_product_${product.barcode}',
              onVisibilityChanged: (visible, _) {
                if (visible) {
                  _visibleShops.add(shop);
                  if (_model.newsPieces.cachedVal.last == newsPiece) {
                    _model.maybeLoadNextNews();
                  }
                } else {
                  _visibleShops.remove(shop);
                }
                _uiAddressesObtainer.onDisplayedEntitiesChanged(
                  displayedEntities: _visibleShops,
                  allEntitiesOrdered: allLoadedShops,
                );
              },
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ProductAtShopNewsPieceWidget(product, shop,
                      _uiAddressesObtainer.requestAddressOf(shop))));
          break;
      }
      widgets.add(widget);
    }
    return widgets;
  }
}

class _ProductLabelWidget extends StatelessWidget {
  const _ProductLabelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Align(
            alignment: Alignment.topRight,
            child: LicenceLabel(
              label:
                  context.strings.news_feed_page_label_for_new_product_at_shop,
              darkBox: true,
            )));
  }
}

class _ProductAtShopNewsPieceWidget extends StatelessWidget {
  final Product product;
  final Shop shop;
  final FutureShortAddress address;
  const _ProductAtShopNewsPieceWidget(this.product, this.shop, this.address,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 12),
        child: Column(children: [
          ProductHeaderWidget(
            product: product,
            imageType: ProductImageType.FRONT,
            height: 200,
            overlay: const _ProductLabelWidget(),
            subtitleOverride: AddressWidget.forShop(shop, address),
            onTap: () {
              ProductPageWrapper.show(context, product);
            },
          ),
        ]),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final GeneralError error;
  final VoidCallback onRetryClick;

  const _ErrorWidget(
      {Key? key, required this.error, required this.onRetryClick})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String errorText;
    if (error == GeneralError.NETWORK) {
      errorText = context.strings.global_network_error;
    } else {
      errorText = context.strings.global_something_went_wrong;
    }
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(errorText,
                  style: TextStyles.normal, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              ButtonFilledPlante.withText(context.strings.global_try_again,
                  onPressed: onRetryClick)
            ])));
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicatorPlante()));
  }
}
