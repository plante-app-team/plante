import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/lang/countries_lang_codes_table.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/mobile_app_config_manager.dart';
import 'package:plante/outside/backend/user_params_auto_wiper.dart';
import 'package:plante/outside/backend/user_params_fetcher.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/directions_manager.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_cacher.dart';
import 'package:plante/outside/map/osm_searcher.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/suggested_products_manager.dart';
import 'package:plante/outside/products/taken_products_images_storage.dart';
import 'package:plante/ui/base/safe_font_environment_detector.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/photos_taker.dart';

void initDI() {
  GetIt.I.registerSingleton<SharedPreferencesHolder>(SharedPreferencesHolder());
  GetIt.I.registerSingleton<Settings>(Settings());
  GetIt.I.registerSingleton<Analytics>(Analytics(GetIt.I.get<Settings>()));
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
  GetIt.I.registerSingleton<LocationController>(LocationController(
      GetIt.I.get<IpLocationProvider>(),
      GetIt.I.get<PermissionsManager>(),
      GetIt.I.get<SharedPreferencesHolder>()));
  GetIt.I.registerSingleton<GoogleAuthorizer>(GoogleAuthorizer());
  GetIt.I.registerSingleton<AppleAuthorizer>(AppleAuthorizer());
  GetIt.I.registerSingleton<PhotosTaker>(PhotosTaker());
  GetIt.I.registerSingleton<Backend>(Backend(
      GetIt.I.get<Analytics>(),
      GetIt.I.get<UserParamsController>(),
      GetIt.I.get<HttpClient>(),
      GetIt.I.get<Settings>()));
  GetIt.I.registerSingleton<MobileAppConfigManager>(MobileAppConfigManager(
      GetIt.I.get<Backend>(),
      GetIt.I.get<UserParamsController>(),
      GetIt.I.get<SharedPreferencesHolder>()));
  GetIt.I.registerSingleton<OpenStreetMap>(OpenStreetMap(
    GetIt.I.get<HttpClient>(),
    GetIt.I.get<Analytics>(),
    GetIt.I.get<MobileAppConfigManager>(),
  ));
  GetIt.I.registerSingleton<AddressObtainer>(
      AddressObtainer(GetIt.I.get<OpenStreetMap>()));
  GetIt.I.registerSingleton<UserLangsManager>(UserLangsManager(
      GetIt.I.get<SysLangCodeHolder>(),
      GetIt.I.get<CountriesLangCodesTable>(),
      GetIt.I.get<LocationController>(),
      GetIt.I.get<AddressObtainer>(),
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
  GetIt.I.registerSingleton<OffApi>(
      OffApi(GetIt.I.get<Settings>(), GetIt.I.get<HttpClient>()));
  GetIt.I.registerSingleton<TakenProductsImagesStorage>(
      TakenProductsImagesStorage());
  GetIt.I.registerSingleton<ProductsManager>(ProductsManager(
      GetIt.I.get<OffApi>(),
      GetIt.I.get<Backend>(),
      GetIt.I.get<TakenProductsImagesStorage>(),
      GetIt.I.get<Analytics>()));
  GetIt.I.registerSingleton<OffShopsManager>(OffShopsManager(
    GetIt.I.get<OffApi>(),
    GetIt.I.get<LatestCameraPosStorage>(),
    GetIt.I.get<AddressObtainer>(),
  ));
  GetIt.I.registerSingleton<ProductsObtainer>(ProductsObtainer(
    GetIt.I.get<ProductsManager>(),
    GetIt.I.get<UserLangsManager>(),
  ));
  GetIt.I.registerSingleton<SuggestedProductsManager>(SuggestedProductsManager(
    GetIt.I.get<OffShopsManager>(),
    GetIt.I.get<UserLangsManager>(),
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
      GetIt.I.get<OsmCacher>()));
  GetIt.I.registerSingleton<RoadsManager>(
      RoadsManager(GetIt.I.get<OpenStreetMap>(), GetIt.I.get<OsmCacher>()));
  GetIt.I.registerSingleton<OsmSearcher>(
      OsmSearcher(GetIt.I.get<OpenStreetMap>()));
  GetIt.I.registerSingleton<DirectionsManager>(DirectionsManager());
  GetIt.I.registerSingleton<SafeFontEnvironmentDetector>(
      SafeFontEnvironmentDetector(
    GetIt.I.get<SysLangCodeHolder>(),
    GetIt.I.get<UserLangsManager>(),
    GetIt.I.get<LocationController>(),
    GetIt.I.get<SharedPreferencesHolder>(),
    GetIt.I.get<AddressObtainer>(),
    GetIt.I.get<CountriesLangCodesTable>(),
  ));
}
