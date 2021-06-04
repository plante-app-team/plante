import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_base.dart';

class MapPageModeSelectShops extends MapPageModeSelectShopsBase {
  MapPageModeSelectShops(MapPageModeParams params) : super(params);
  @override
  void onDoneClick() async {
    model.finishWith(context, selectedShops().toList());
  }
}
