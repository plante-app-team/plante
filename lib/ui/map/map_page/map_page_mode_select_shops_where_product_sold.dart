import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_create_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold_base.dart';

class MapPageModeSelectShopsWhereProductSold
    extends MapPageModeSelectShopsWhereProductSoldBase {
  MapPageModeSelectShopsWhereProductSold(MapPageModeParams params)
      : super(params, nameForAnalytics: 'select_shops_where_product_sold');
  @override
  void onDoneClick() async {
    model.finishWith(context, selectedShops().toList());
  }

  @override
  void onAddShopClicked() {
    final nextModeMaker = () {
      return MapPageModeSelectShopsWhereProductSold(params);
    };
    switchModeTo(MapPageModeCreateShop(params, nextModeMaker));
  }
}
