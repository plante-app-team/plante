import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/lang/input_products_lang_storage.dart';
import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/user_params_auto_wiper.dart';
import 'package:plante/outside/http_client.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/outside/products/taken_products_images_storage.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/photos_taker.dart';
import 'package:plante/user_params_fetcher.dart';

void initDI() {
  GetIt.I.registerSingleton<SharedPreferencesHolder>(SharedPreferencesHolder());
  GetIt.I.registerSingleton<Settings>(Settings());
  GetIt.I.registerSingleton<Analytics>(Analytics(GetIt.I.get<Settings>()));
  GetIt.I.registerSingleton<LatestCameraPosStorage>(
      LatestCameraPosStorage(GetIt.I.get<SharedPreferencesHolder>()));
  GetIt.I.registerSingleton<SysLangCodeHolder>(SysLangCodeHolder());
  GetIt.I.registerSingleton<InputProductsLangStorage>(InputProductsLangStorage(
      GetIt.I.get<SharedPreferencesHolder>(),
      GetIt.I.get<SysLangCodeHolder>()));
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
  GetIt.I.registerSingleton<OpenStreetMap>(
      OpenStreetMap(GetIt.I.get<HttpClient>()));
  GetIt.I.registerSingleton<AddressObtainer>(
      AddressObtainer(GetIt.I.get<OpenStreetMap>()));
  GetIt.I.registerSingleton<GoogleAuthorizer>(GoogleAuthorizer());
  GetIt.I.registerSingleton<AppleAuthorizer>(AppleAuthorizer());
  GetIt.I.registerSingleton<PhotosTaker>(PhotosTaker());
  GetIt.I.registerSingleton<Backend>(Backend(
      GetIt.I.get<Analytics>(),
      GetIt.I.get<UserParamsController>(),
      GetIt.I.get<HttpClient>(),
      GetIt.I.get<Settings>()));
  GetIt.I.registerSingleton<UserParamsAutoWiper>(UserParamsAutoWiper(
      GetIt.I.get<Backend>(), GetIt.I.get<UserParamsController>()));
  GetIt.I.registerSingleton<OffApi>(OffApi(GetIt.I.get<Settings>()));
  GetIt.I.registerSingleton<TakenProductsImagesStorage>(
      TakenProductsImagesStorage());
  GetIt.I.registerSingleton<ProductsManager>(ProductsManager(
      GetIt.I.get<OffApi>(),
      GetIt.I.get<Backend>(),
      GetIt.I.get<TakenProductsImagesStorage>()));
  GetIt.I.registerSingleton<ProductsObtainer>(ProductsObtainer(
    GetIt.I.get<ProductsManager>(),
    GetIt.I.get<SysLangCodeHolder>(),
  ));
  GetIt.I.registerSingleton<UserParamsFetcher>(UserParamsFetcher(
      GetIt.I.get<Backend>(), GetIt.I.get<UserParamsController>()));
  GetIt.I.registerSingleton<ViewedProductsStorage>(ViewedProductsStorage());
  GetIt.I.registerSingleton<ShopsManager>(ShopsManager(
      GetIt.I.get<OpenStreetMap>(),
      GetIt.I.get<Backend>(),
      GetIt.I.get<ProductsObtainer>(),
      GetIt.I.get<Analytics>()));
}
