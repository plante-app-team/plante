import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/backend/user_params_auto_wiper.dart';
import 'package:plante/outside/backend/user_params_fetcher.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/extra_properties/map_extra_properties_cacher.dart';
import 'package:plante/outside/map/extra_properties/products_at_shops_extra_properties_manager.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_cacher.dart';
import 'package:plante/outside/map/osm/osm_searcher.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/user_address/caching_user_address_pieces_obtainer.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_cacher.dart';
import 'package:plante/outside/off/off_geo_helper.dart';
import 'package:plante/outside/off/off_shops_list_obtainer.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/off/off_vegan_barcodes_obtainer.dart';
import 'package:plante/outside/off/off_vegan_barcodes_storage.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggested_products_manager.dart';
import 'package:plante/outside/products/taken_products_images_storage.dart';
import 'package:plante/ui/base/safe_font_environment_detector.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/photos/photos_taker.dart';

void initDI() {
  GetIt.I.registerSingleton<SharedPreferencesHolder>(SharedPreferencesHolder());
  GetIt.I.registerSingleton<Settings>(Settings());
  GetIt.I.registerSingleton<Analytics>(Analytics());
  GetIt.I.registerSingleton<LatestCameraPosStorage>(
      LatestCameraPosStorage(GetIt.I.get<SharedPreferencesHolder>()));
  GetIt.I.registerSingleton<SysLangCodeHolder>(SysLangCodeHolder());
  GetIt.I.registerSingleton<CountriesLangCodesTable>(
      CountriesLangCodesTable(GetIt.I.get<Analytics>()));
  GetIt.I.registerSingleton<PermissionsManager>(PermissionsManager());
  GetIt.I.registerSingleton<RouteObserver<ModalRoute>>(
      RouteObserver<ModalRoute>());
  GetIt.I.registerSingleton<UserParamsController>(UserParamsController());
  GetIt.I.registerSingleton<HttpClient>(HttpClient());
  GetIt.I.registerSingleton<IpLocationProvider>(
      IpLocationProvider(GetIt.I.get<HttpClient>()));
  GetIt.I.registerSingleton<UserLocationManager>(UserLocationManager(
      GetIt.I.get<IpLocationProvider>(),
      GetIt.I.get<PermissionsManager>(),
      GetIt.I.get<SharedPreferencesHolder>()));
  GetIt.I.registerSingleton<GoogleAuthorizer>(GoogleAuthorizer());
  GetIt.I.registerSingleton<AppleAuthorizer>(AppleAuthorizer());
  GetIt.I.registerSingleton<PhotosTaker>(
      PhotosTaker(GetIt.I.get<SharedPreferencesHolder>()));
  GetIt.I.registerSingleton<Backend>(Backend(GetIt.I.get<Analytics>(),
      GetIt.I.get<UserParamsController>(), GetIt.I.get<HttpClient>()));
  GetIt.I.registerSingleton<MobileAppConfigManager>(MobileAppConfigManager(
      GetIt.I.get<Backend>(),
      GetIt.I.get<UserParamsController>(),
      GetIt.I.get<SharedPreferencesHolder>()));
  GetIt.I.registerSingleton<UserAvatarManager>(UserAvatarManager(
    GetIt.I.get<Backend>(),
    GetIt.I.get<UserParamsController>(),
    GetIt.I.get<PhotosTaker>(),
  ));
  GetIt.I.registerSingleton<OpenStreetMap>(OpenStreetMap(
    GetIt.I.get<HttpClient>(),
    GetIt.I.get<Analytics>(),
    GetIt.I.get<MobileAppConfigManager>(),
  ));
  GetIt.I.registerSingleton<AddressObtainer>(
      AddressObtainer(GetIt.I.get<OpenStreetMap>()));
  GetIt.I.registerSingleton<CachingUserAddressPiecesObtainer>(
      CachingUserAddressPiecesObtainer(
    GetIt.I.get<SharedPreferencesHolder>(),
    GetIt.I.get<UserLocationManager>(),
    GetIt.I.get<LatestCameraPosStorage>(),
    GetIt.I.get<AddressObtainer>(),
  ));
  GetIt.I.registerSingleton<UserLangsManager>(UserLangsManager(
      GetIt.I.get<SysLangCodeHolder>(),
      GetIt.I.get<CountriesLangCodesTable>(),
      GetIt.I.get<UserLocationManager>(),
      GetIt.I.get<CachingUserAddressPiecesObtainer>(),
      GetIt.I.get<SharedPreferencesHolder>(),
      GetIt.I.get<UserParamsController>(),
      GetIt.I.get<Backend>(),
      GetIt.I.get<Analytics>()));
  GetIt.I.registerSingleton<InputProductsLangStorage>(InputProductsLangStorage(
      GetIt.I.get<SharedPreferencesHolder>(),
      GetIt.I.get<UserLangsManager>(),
      GetIt.I.get<Analytics>()));
  GetIt.I.registerSingleton<UserParamsAutoWiper>(UserParamsAutoWiper(
      GetIt.I.get<Backend>(), GetIt.I.get<UserParamsController>()));
  GetIt.I.registerSingleton<OffApi>(OffApi(GetIt.I.get<HttpClient>()));
  GetIt.I.registerSingleton<OffGeoHelper>(OffGeoHelper(
    GetIt.I.get<OffApi>(),
    GetIt.I.get<AddressObtainer>(),
    GetIt.I.get<Analytics>(),
  ));
  GetIt.I.registerSingleton<TakenProductsImagesStorage>(
      TakenProductsImagesStorage());
  GetIt.I.registerSingleton<ProductsManager>(ProductsManager(
      GetIt.I.get<OffApi>(),
      GetIt.I.get<Backend>(),
      GetIt.I.get<TakenProductsImagesStorage>(),
      GetIt.I.get<Analytics>()));
  GetIt.I.registerSingleton<OffShopsListObtainer>(OffShopsListObtainer(
    GetIt.I.get<OffApi>(),
  ));
  GetIt.I.registerSingleton<OffCacher>(OffCacher());
  GetIt.I.registerSingleton<OffVeganBarcodesStorage>(OffVeganBarcodesStorage(
    GetIt.I.get<OffCacher>(),
  ));
  GetIt.I.registerSingleton<OffVeganBarcodesObtainer>(OffVeganBarcodesObtainer(
    GetIt.I.get<OffApi>(),
    GetIt.I.get<OffVeganBarcodesStorage>(),
  ));
  GetIt.I.registerSingleton<OffShopsManager>(OffShopsManager(
    GetIt.I.get<OffVeganBarcodesObtainer>(),
    GetIt.I.get<OffShopsListObtainer>(),
  ));
  GetIt.I.registerSingleton<ProductsObtainer>(ProductsObtainer(
    GetIt.I.get<ProductsManager>(),
    GetIt.I.get<UserLangsManager>(),
  ));
  GetIt.I
      .registerSingleton<MapExtraPropertiesCacher>(MapExtraPropertiesCacher());
  GetIt.I.registerSingleton<ProductsAtShopsExtraPropertiesManager>(
      ProductsAtShopsExtraPropertiesManager(
    GetIt.I.get<MapExtraPropertiesCacher>(),
  ));
  GetIt.I.registerSingleton<UserParamsFetcher>(UserParamsFetcher(
      GetIt.I.get<UserParamsController>(),
      GetIt.I.get<MobileAppConfigManager>()));
  GetIt.I.registerSingleton<ViewedProductsStorage>(ViewedProductsStorage());
  GetIt.I.registerSingleton<OsmCacher>(OsmCacher());
  GetIt.I.registerSingleton<ShopsManager>(ShopsManager(
    GetIt.I.get<OpenStreetMap>(),
    GetIt.I.get<Backend>(),
    GetIt.I.get<ProductsObtainer>(),
    GetIt.I.get<Analytics>(),
    GetIt.I.get<OsmCacher>(),
    GetIt.I.get<OffGeoHelper>(),
  ));
  GetIt.I.registerSingleton<SuggestedProductsManager>(SuggestedProductsManager(
    GetIt.I.get<ShopsManager>(),
    GetIt.I.get<OffShopsManager>(),
    GetIt.I.get<ProductsAtShopsExtraPropertiesManager>(),
  ));
  GetIt.I.registerSingleton<RoadsManager>(
      RoadsManager(GetIt.I.get<OpenStreetMap>(), GetIt.I.get<OsmCacher>()));
  GetIt.I.registerSingleton<OsmSearcher>(
      OsmSearcher(GetIt.I.get<OpenStreetMap>()));
  GetIt.I.registerSingleton<DirectionsManager>(DirectionsManager());
  GetIt.I.registerSingleton<SafeFontEnvironmentDetector>(
      SafeFontEnvironmentDetector(
    GetIt.I.get<SysLangCodeHolder>(),
    GetIt.I.get<UserLangsManager>(),
    GetIt.I.get<SharedPreferencesHolder>(),
    GetIt.I.get<CountriesLangCodesTable>(),
    GetIt.I.get<CachingUserAddressPiecesObtainer>(),
  ));
}
