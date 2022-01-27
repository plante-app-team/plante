import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/geolocator_wrapper.dart';
import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/osm/osm_nominatim.dart';
import 'package:plante/outside/map/osm/osm_overpass.dart';
import 'package:plante/outside/map/osm/osm_searcher.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/photos/photos_taker.dart';

@GenerateMocks([
  AddressObtainer,
  AppleAuthorizer,
  Backend,
  BackendObserver,
  DirectionsManager,
  GeolocatorWrapper,
  GoogleAuthorizer,
  GoogleMapController,
  IpLocationProvider,
  LatestCameraPosStorage,
  UserLocationManager,
  MobileAppConfigManager,
  OffApi,
  OffShopsManager,
  OsmNominatim,
  OsmOverpass,
  OsmSearcher,
  PermissionsManager,
  PhotosTaker,
  ProductsManager,
  ProductsObtainer,
  RoadsManager,
  RouteObserver,
  ShopsManager,
  ShopsManagerListener,
  SuggestedProductsManager,
  SysLangCodeHolder,
  UserLangsManager,
  UserLangsManagerObserver,
  UserParamsController,
  ViewedProductsStorage,
])
void unusedFunctionForCommonMocks() {}

@GenerateMocks([],
    customMocks: [MockSpec<NavigatorObserver>(returnNullOnMissingStub: true)])
void unusedFunctionForCommonStubbedMocks() {}
