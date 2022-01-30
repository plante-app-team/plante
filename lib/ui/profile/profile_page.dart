import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/profile/components/avatar_widget.dart';
import 'package:plante/ui/profile/components/products_history_widget.dart';
import 'package:plante/ui/profile/components/profile_check_button_wrapper.dart';
import 'package:plante/ui/profile/edit_profile_page.dart';
import 'package:plante/ui/settings/settings_page.dart';

enum ProfilePageProductsList {
  MY_PRODUCTS,
  HISTORY,
}

class ProfilePage extends PagePlante {
  final _testingStorage = _TestingStorage();
  ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();

  ProfilePageProductsList? displayedProductsList() {
    return _testingStorage.productsListCallback?.call();
  }
}

class _TestingStorage {
  ResCallback<ProfilePageProductsList>? productsListCallback;
}

class _ProfilePageState extends PageStatePlante<ProfilePage>
    implements UserAvatarManagerObserver, UserParamsControllerObserver {
  final _userParamsController = GetIt.I.get<UserParamsController>();
  final _avatarManager = GetIt.I.get<UserAvatarManager>();
  final _viewedProductsStorage = GetIt.I.get<ViewedProductsStorage>();
  final _productsObtainer = GetIt.I.get<ProductsObtainer>();

  final _productsListPagerController = PageController();

  late final _userParams = UIValue<UserParams?>(null, ref);
  late final _avatar = UIValue<Uri?>(null, ref);
  late final _shownProducts = UIValue<ProfilePageProductsList>(
      ProfilePageProductsList.MY_PRODUCTS, ref);

  _ProfilePageState() : super('ProfilePage');

  @override
  void initState() {
    super.initState();
    widget._testingStorage.productsListCallback =
        () => _shownProducts.cachedVal;

    _avatarManager.addObserver(this);
    _userParamsController.addObserver(this);
    _productsListPagerController.addListener(() {
      final pageIndex = _productsListPagerController.page?.round() ??
          _shownProducts.cachedVal.index;
      final page = ProfilePageProductsList.values[pageIndex];
      if (page != _shownProducts.cachedVal) {
        analytics.sendEvent(page.analyticsEvent());
        _shownProducts.setValue(page);
      }
    });
    _initAsync();
  }

  void _initAsync() async {
    _userParams.setValue(await _userParamsController.getUserParams());
    _avatar.setValue(await _avatarManager.userAvatarUri());
  }

  @override
  void dispose() {
    _avatarManager.removeObserver(this);
    _userParamsController.removeObserver(this);
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorsPlante.lightGrey,
        body: SafeArea(
            child: Column(children: [
          HeaderPlante(
              title: const SizedBox(),
              spacingTop: 0,
              spacingBottom: 0,
              height: 64,
              rightActionPadding: 12,
              rightAction: IconButton(
                  key: const Key('settings_button'),
                  onPressed: _openSettings,
                  icon: SvgPicture.asset('assets/settings.svg'))),
          Material(
              color: Colors.white,
              child: Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: Column(children: [
                    Row(children: [
                      SizedBox(
                          width: 75,
                          height: 75,
                          child: consumer((ref) => AvatarWidget(
                              uri: _avatar.watch(ref),
                              authHeaders:
                                  _avatarManager.userAvatarAuthHeaders()))),
                      const SizedBox(width: 16),
                      consumer((ref) {
                        final userParams = _userParams.watch(ref);
                        if (userParams == null) {
                          return const SizedBox();
                        }
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userParams.name ?? '',
                                  style: TextStyles.headline3
                                      .copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              if (userParams.selfDescription != null)
                                Text(userParams.selfDescription!,
                                    style: TextStyles.hint),
                            ]);
                      }),
                    ]),
                    const SizedBox(height: 12),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                            key: const Key('edit_profile_button'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: _onEditProfileClick,
                            child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                    context.strings.profile_page_edit_profile,
                                    style: TextStyles.smallBoldBlack)))),
                    const SizedBox(height: 16),
                  ]))),
          Expanded(
              child: Stack(children: [
            PageView(
              key: const Key('products_lists_page_view'),
              controller: _productsListPagerController,
              children: [
                const Text('page1'),
                ProductsHistoryWidget(_viewedProductsStorage, _productsObtainer,
                    _userParamsController,
                    topSpacing: 62),
              ],
            ),
            ClipRect(
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                    child: Container(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: Row(children: [
                          const SizedBox(width: 16),
                          _productsCheckButton(0),
                          const SizedBox(width: 9),
                          _productsCheckButton(1),
                          const SizedBox(width: 16),
                        ])))),
          ])),
        ])));
  }

  Widget _productsCheckButton(int index) {
    final productsList = ProfilePageProductsList.values[index];
    return consumer((ref) => ProfileCheckButtonWrapper(
        checked: _shownProducts.watch(ref) == productsList,
        text: productsList.localize(context),
        onChanged: (value) {
          _onProductsCheckButtonChange(value, productsList);
        }));
  }

  void _onProductsCheckButtonChange(bool value, ProfilePageProductsList list) {
    if (value == true) {
      _productsListPagerController.animateToPage(
          ProfilePageProductsList.values.indexOf(list),
          duration: DURATION_DEFAULT,
          curve: Curves.linear);
    }
  }

  void _onEditProfileClick() {
    EditProfilePage.show(
        context: context,
        initialUserParams: _userParams.cachedVal!,
        initialUserAvatar: _avatar.cachedVal);
  }

  void _openSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SettingsPage()));
  }

  @override
  void onUserAvatarChange() async {
    _avatar.setValue(await _avatarManager.userAvatarUri());
  }

  @override
  void onUserParamsUpdate(UserParams? userParams) async {
    _userParams.setValue(await _userParamsController.getUserParams());
  }
}

extension on ProfilePageProductsList {
  String localize(BuildContext context) {
    switch (this) {
      case ProfilePageProductsList.MY_PRODUCTS:
        return context.strings.profile_page_products_my_products;
      case ProfilePageProductsList.HISTORY:
        return context.strings.profile_page_products_history;
    }
  }

  String analyticsEvent() {
    switch (this) {
      case ProfilePageProductsList.MY_PRODUCTS:
        return 'profile_products_switch_my_products';
      case ProfilePageProductsList.HISTORY:
        return 'profile_products_switch_history';
    }
  }
}
