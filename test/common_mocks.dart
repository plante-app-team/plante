import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/location/geolocator_wrapper.dart';
import 'package:plante/location/ip_location_provider.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/products/products_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/photos_taker.dart';

import 'common_mocks.mocks.dart';

@GenerateMocks([
  AddressObtainer,
  AppleAuthorizer,
  Backend,
  BackendObserver,
  GeolocatorWrapper,
  GoogleAuthorizer,
  GoogleMapController,
  IpLocationProvider,
  LatestCameraPosStorage,
  LocationController,
  OffApi,
  OpenStreetMap,
  PermissionsManager,
  PhotosTaker,
  ProductsManager,
  ProductsObtainer,
  RouteObserver,
  ShopsManager,
  ShopsManagerListener,
  SysLangCodeHolder,
  UserLangsManager,
  UserParamsController,
  ViewedProductsStorage,
])
void unusedFunctionForCommonMocks() {}

MockUserLangsManager mockUserLangsManagerWith(List<LangCode> langCodes) {
  final userLangsManager = MockUserLangsManager();
  when(userLangsManager.getUserLangs())
      .thenAnswer((_) async => UserLangs((e) => e
        ..auto = true
        ..sysLang = langCodes.first
        ..langs.addAll(langCodes)));
  when(userLangsManager.setManualUserLangs(any)).thenAnswer((invc) async {
    final langs = invc.positionalArguments[0] as List<LangCode>;
    when(userLangsManager.getUserLangs())
        .thenAnswer((_) async => UserLangs((e) => e
          ..auto = false
          ..sysLang = langs.first
          ..langs.addAll(langs)));
    return Ok(None());
  });
  return userLangsManager;
}
