import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_products_obtainer.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

class ProfilePageTestCommons {
  static const avatarId = FakeUserAvatarManager.DEFAULT_AVATAR_ID;
  static final imagePath =
      Uri.file(File('./test/assets/img.jpg').absolute.path);
  late FakeAnalytics analytics;
  late FakeUserParamsController userParamsController;
  late FakeUserAvatarManager userAvatarManager;
  late FakeProductsObtainer productsObtainer;
  late ViewedProductsStorage viewedProductsStorage;

  ProfilePageTestCommons._();

  static Future<ProfilePageTestCommons> create() async {
    final instance = ProfilePageTestCommons._();
    await instance._initAsync();
    return instance;
  }

  Future<void> _initAsync() async {
    await GetIt.I.reset();

    analytics = FakeAnalytics();
    userParamsController = FakeUserParamsController();
    userAvatarManager = FakeUserAvatarManager(userParamsController);

    GetIt.I.registerSingleton<Analytics>(analytics);
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    GetIt.I.registerSingleton<UserAvatarManager>(userAvatarManager);
    GetIt.I.registerSingleton<Settings>(Settings());
    GetIt.I
        .registerSingleton<SysLangCodeHolder>(SysLangCodeHolder.inited('en'));
    GetIt.I.registerSingleton<Backend>(MockBackend());
    productsObtainer = FakeProductsObtainer();
    GetIt.I.registerSingleton<ProductsObtainer>(productsObtainer);
    viewedProductsStorage = ViewedProductsStorage(
        loadPersistentProducts: false, storePersistentProducts: false);
    GetIt.I.registerSingleton<ViewedProductsStorage>(viewedProductsStorage);
  }
}
