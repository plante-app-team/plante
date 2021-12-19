import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:plante/model/ingredient.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/moderator_choice_reason.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/product_lang_slice.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/veg_status.dart';
import 'package:plante/model/veg_status_source.dart';
import 'package:plante/outside/backend/backend_product.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';
import 'package:plante/outside/backend/shops_in_bounds_response.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_short_address.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/off/off_shop.dart';

part 'build_value_helper.g.dart';

@SerializersFor([
  UserParams,
  BackendProduct,
  VegStatus,
  VegStatusSource,
  Product,
  ProductLangSlice,
  Ingredient,
  BackendProductsAtShop,
  BackendShop,
  MobileAppConfig,
  OsmShop,
  OsmRoad,
  Shop,
  OsmAddress,
  OsmShortAddress,
  OffShop,
  ModeratorChoiceReason,
  LangCode,
  UserLangs,
  ShopsInBoundsResponse,
])
final Serializers _serializers = _$_serializers;
final _jsonSerializers = (_serializers.toBuilder()
      ..add(OsmUIDBuildValueSerializer())
      ..addPlugin(StandardJsonPlugin())
      ..addBuilderFactory(const FullType(BuiltList, [FullType(Ingredient)]),
          () => ListBuilder<Ingredient>()))
    .build();

class BuildValueHelper {
  static final Serializers serializers = _serializers;
  static final jsonSerializers = _jsonSerializers;
}
