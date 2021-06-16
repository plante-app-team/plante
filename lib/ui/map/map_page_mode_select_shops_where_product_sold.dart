import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_where_product_sold_base.dart';

class MapPageModeSelectShopsWhereProductSold
    extends MapPageModeSelectShopsWhereProductSoldBase {
  MapPageModeSelectShopsWhereProductSold(MapPageModeParams params)
      : super(params);
  @override
  void onDoneClick() async {
    model.finishWith(context, selectedShops().toList());
  }
}
