import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/backend/user_reports_maker.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_where_product_sold_obtainer.dart';
import 'package:plante/outside/news/news_cluster.dart';
import 'package:plante/outside/news/news_feed_manager.dart';
import 'package:plante/outside/news/news_piece_product_at_shop.dart';
import 'package:plante/outside/news/news_piece_type.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/animated_list_simple_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/news/news_feed_page_model.dart';
import 'package:plante/ui/news/news_piece_product_at_shop_widget.dart';
import 'package:plante/ui/report/report_dialog.dart';

class NewsFeedPage extends PagePlante {
  static const _DEFAULT_NEWS_LIFETIME_SECS = 60 * 6; // 5 minutes
  static const _DEFAULT_RELOAD_NEWS_AFTER_KMS = 7;

  final int newsLifetimeSecs;
  final int reloadNewsAfterKms;

  const NewsFeedPage(
      {Key? key,
      this.newsLifetimeSecs = _DEFAULT_NEWS_LIFETIME_SECS,
      this.reloadNewsAfterKms = _DEFAULT_RELOAD_NEWS_AFTER_KMS})
      : super(key: key);

  @override
  _NewsFeedPageState createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends PageStatePlante<NewsFeedPage> {
  final _reportsMaker = GetIt.I.get<UserReportsMaker>();
  late final _model = NewsFeedPageModel(
    GetIt.I.get<NewsFeedManager>(),
    GetIt.I.get<ProductsObtainer>(),
    GetIt.I.get<ShopsManager>(),
    GetIt.I.get<LatestCameraPosStorage>(),
    GetIt.I.get<ShopsWhereProductSoldObtainer>(),
    GetIt.I.get<UserAvatarManager>(),
    GetIt.I.get<Backend>(),
    uiValuesFactory,
  );

  final _visibleShops = <Shop>{};
  late final _loadingByPullToRefresh = UIValue(false, ref);

  _NewsFeedPageState() : super('PageStatePlante');

  @override
  void initState() {
    super.initState();
    _model.setNewsLifetimeSecs(widget.newsLifetimeSecs);
    _model.setNewsReloadAfterKms(widget.reloadNewsAfterKms);
  }

  @override
  void didUpdateWidget(NewsFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _model.setNewsLifetimeSecs(widget.newsLifetimeSecs);
    _model.setNewsReloadAfterKms(widget.reloadNewsAfterKms);
  }

  @override
  Widget buildPage(BuildContext context) {
    final content = Stack(children: [
      consumer((ref) {
        final newsWidgets = _newsPiecesWidgets(_model.news.watch(ref));
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
        if (fillSpace && _model.reloading.watch(ref)) {
          return makeStack(const _LoadingWidget());
        } else if (!fillSpace && !_model.reloading.watch(ref)) {
          return const _LoadingWidget();
        }
      }
      final error = _model.lastError.watch(ref);
      if (error != null) {
        final errorWidget = () =>
            _ErrorWidget(error: error, onRetryClick: _model.maybeLoadNextNews);
        if (fillSpace && _model.news.watch(ref).isEmpty) {
          return makeStack(errorWidget());
        } else if (!fillSpace && !_model.news.watch(ref).isEmpty) {
          return errorWidget();
        }
      }
      return const SizedBox();
    });
  }

  List<Widget> _newsPiecesWidgets(List<NewsCluster> news) {
    final widgets = <Widget>[];
    for (final cluster in news) {
      final Widget widget;
      switch (cluster.type) {
        case NewsPieceType.UNKNOWN:
          widget = const SizedBox();
          break;
        case NewsPieceType.PRODUCT_AT_SHOP:
          widget = _createWidgetProductAtShop(cluster);
          break;
      }
      widgets.add(widget);
    }
    return widgets;
  }

  Widget _createWidgetProductAtShop(NewsCluster cluster) {
    final typedData =
        cluster.newsPieces.first.typedData as NewsPieceProductAtShop;
    final product = _model.getProductWith(typedData.barcode);
    final shop = _model.getShopWith(typedData.shopUID);
    if (product == null || shop == null) {
      return const SizedBox.shrink();
    }
    return VisibilityDetectorPlante(
        keyStr: 'shop_${shop.osmUID}_product_${product.barcode}',
        onVisibilityChanged: (visible, _) {
          if (visible) {
            _visibleShops.add(shop);
            final news = _model.news.cachedVal;
            if (news.isNotEmpty && news.last == cluster) {
              _model.maybeLoadNextNews();
            }
          } else {
            _visibleShops.remove(shop);
          }
        },
        child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NewsPieceProductAtShopWidget(
                product,
                cluster,
                _model.authorAvatarUrl(cluster),
                _model.authHeaders(),
                () => _onProductLocationTap(product),
                () => _onNewsPieceReportTap(cluster))));
  }

  void _onProductLocationTap(Product product) async {
    final shopsRes = await _model.obtainShopsWhereSold(product);
    if (shopsRes.isErr) {
      final error = shopsRes.unwrapErr().toGeneral();
      if (error == GeneralError.NETWORK) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
      return;
    }
    _showOnMap(shopsRes.unwrap());
  }

  void _onNewsPieceReportTap(NewsCluster cluster) {
    // Let's assume the first news piece of the cluster is reported,
    // because that's the one that the user has seen
    final newsPiece = cluster.newsPieces.first;
    showDialog(
      context: context,
      builder: (context) {
        return ReportDialog.forNewsPiece(
            newsPieceId: newsPiece.serverId.toString(),
            reportsMaker: _reportsMaker);
      },
    );
  }

  void _showOnMap(List<Shop> shops) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(
            requestedMode: MapPageRequestedMode.DEMONSTRATE_SHOPS,
            initialSelectedShops: shops,
          ),
        ));
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
