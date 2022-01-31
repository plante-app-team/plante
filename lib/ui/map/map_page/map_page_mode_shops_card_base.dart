import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';

abstract class MapPageModeShopsCardBase extends MapPageMode {
  late final UIValue<List<Shop>> _displayedShops;
  final _actuallyVisibleShops = <Shop>{};
  late final UiListAddressesObtainer addressesObtainer;

  MapPageModeShopsCardBase(MapPageModeParams params,
      {required String nameForAnalytics})
      : super(params, nameForAnalytics: nameForAnalytics) {
    _displayedShops = createUIValue([]);
    addressesObtainer = model.createListAddressesObtainer();
  }

  @mustCallSuper
  @override
  void deinit() {
    addressesObtainer.onDisplayedEntitiesChanged(
        displayedEntities: const <Shop>[], allEntitiesOrdered: const <Shop>[]);
    super.deinit();
  }

  @protected
  Widget createCardFor(
      Shop shop, FutureShortAddress address, ArgCallback<Shop>? cancelCallback);

  @mustCallSuper
  @override
  Set<Shop> accentedShops() => _displayedShops.cachedVal.toSet();

  @mustCallSuper
  @override
  void onMarkerClick(Iterable<Shop> shops) {
    _setDisplayedShops(shops);
  }

  void _setDisplayedShops(Iterable<Shop> shops) {
    if (listEquals(shops.toList(), _displayedShops.cachedVal)) {
      return;
    }
    final displayedShops = shops.toList();
    displayedShops.sort((a, b) => b.productsCount - a.productsCount);
    _displayedShops.setValue(displayedShops);
    updateMap();
  }

  @override
  void onShopsUpdated(Map<OsmUID, Shop> shops) {
    if (_displayedShops.cachedVal.isEmpty) {
      return;
    }
    final displayedShops = _displayedShops.cachedVal.toList();
    final oldDisplayedShops = displayedShops.toList();
    for (var index = 0; index < displayedShops.length; ++index) {
      final shop = displayedShops[index];
      displayedShops[index] = shops[shop.osmUID] ?? shop;
    }
    if (!listEquals(oldDisplayedShops, displayedShops)) {
      _displayedShops.setValue(displayedShops);
      updateMap();
    }
  }

  @protected
  Widget shopsCardsWidget() {
    return consumer((ref) {
      final displayedShops = _displayedShops.watch(ref);
      final Widget actualWidget;
      if (displayedShops.isEmpty) {
        actualWidget = const SizedBox.shrink();
      } else if (displayedShops.length == 1) {
        actualWidget = _onlyOneShopSheet(displayedShops);
      } else {
        actualWidget = _draggableScrollableSheet(displayedShops);
      }
      return AnimatedSwitcher(duration: DURATION_DEFAULT, child: actualWidget);
    });
  }

  Widget _onlyOneShopSheet(List<Shop> displayedShops) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 400) {
              hideShopsCard();
            }
          },
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  elevation: 3,
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 10, right: 10, bottom: 5),
                            child: InkWell(
                              key: const Key('card_cancel_btn'),
                              onTap: hideShopsCard,
                              child: SvgPicture.asset(
                                'assets/cancel_circle.svg',
                              ),
                            ),
                          ),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: TextDirection.rtl,
                              children: [
                                Expanded(
                                    child: _buildShopCard(
                                        context, displayedShops, 0)),
                              ]),
                        ]),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _draggableScrollableSheet(List<Shop> displayedShops) {
    double draggableSize = 0.35;
    double maxChildSize = 0.75;
    if (Platform.isIOS) {
      if (MediaQuery.of(context).size.height > 670) {
        draggableSize = 0.30;
        maxChildSize = 0.80;
      }
    } else {
      draggableSize = MediaQuery.of(context).size.height < 670 ? 0.40 : 0.35;
    }
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent == notification.minExtent) {
          hideShopsCard();
        }
        return true;
      },
      child: DraggableScrollableSheet(
          key: const Key('shop_card_scroll'),
          initialChildSize: draggableSize,
          minChildSize: 0.06,
          maxChildSize: maxChildSize,
          builder: (context, shopScrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
              ),
              child: CustomScrollView(
                controller: shopScrollController,
                slivers: [
                  SliverAppBar(
                    elevation: 0,
                    expandedHeight: 2,
                    pinned: true,
                    backgroundColor: Colors.white,
                    shape: const ContinuousRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30))),
                    flexibleSpace: Padding(
                      padding:
                          const EdgeInsets.only(top: 8, left: 160, right: 160),
                      child: Container(
                          height: 2,
                          width: 5,
                          decoration: BoxDecoration(
                              color: ColorsPlante.divider,
                              borderRadius: BorderRadius.circular(30))),
                    ),
                    actions: [
                      InkWell(
                        key: const Key('card_cancel_btn'),
                        onTap: hideShopsCard,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 10, top: 5, bottom: 3),
                          child: SvgPicture.asset(
                            'assets/cancel_circle.svg',
                          ),
                        ),
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(-30),
                      child: Container(), //hack to make appbar smaller
                    ),
                  ),
                  _shopCards(displayedShops)
                ],
              ),
            );
          }),
    );
  }

  Widget _shopCards(List<Shop> displayedShops) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) =>
            _buildShopCard(context, displayedShops, index),
        childCount: math.max(0, displayedShops.length * 2 - 1),
      ),
    );
  }

  Widget _buildShopCard(
      BuildContext context, List<Shop> displayedShops, int index) {
    final int itemIndex = index ~/ 2;
    if (index.isEven) {
      final shop = displayedShops[itemIndex];
      return Column(children: [
        VisibilityDetectorPlante(
            keyStr: shop.osmUID.toString(),
            onVisibilityChanged: (visible, _) {
              if (visible) {
                _actuallyVisibleShops.add(shop);
              } else {
                _actuallyVisibleShops.remove(shop);
              }
              addressesObtainer.onDisplayedEntitiesChanged(
                  displayedEntities: _actuallyVisibleShops,
                  allEntitiesOrdered: displayedShops);
            },
            child: createCardFor(shop, addressesObtainer.requestAddressOf(shop),
                (Shop shop) => hideShopsCard())),
      ]);
    }
    return const Divider(
      height: 2,
      color: ColorsPlante.divider,
      indent: 16,
      endIndent: 16,
      thickness: 1,
    );
  }

  @protected
  void hideShopsCard() {
    _displayedShops.setValue([]);
    updateMap();
  }

  @override
  void deselectShops() {
    hideShopsCard();
  }

  @mustCallSuper
  @override
  Future<bool> onWillPop() async {
    if (_displayedShops.cachedVal.isNotEmpty) {
      hideShopsCard();
      return false;
    }
    return true;
  }
}
