import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/first_screen/external_auth_page.dart';
import 'package:plante/ui/first_screen/init_user_page.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/main/main_page.dart';

class MyAppWidget extends StatefulWidget {
  final UserParams? _initialUserParams;

  const MyAppWidget(this._initialUserParams);

  @override
  State<StatefulWidget> createState() => _MyAppWidgetState(_initialUserParams);
}

class _MyAppWidgetState extends State<MyAppWidget>
    implements UserParamsControllerObserver {
  UserParams? _userParams;

  _MyAppWidgetState(this._userParams) {
    GetIt.I.get<UserParamsController>().addObserver(this);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!
        .addObserver(_AppForegroundDetector(setSystemUIOverlayStyle));
  }

  Future<bool> _onUserParamsSpecified(UserParams params) async {
    Log.i('MyAppWidget._onUserParamsSpecified: $params');
    final paramsController = GetIt.I.get<UserParamsController>();

    // Update on backend
    final result = await GetIt.I.get<Backend>().updateUserParams(params,
        backendClientTokenOverride: params.backendClientToken);
    if (result.isOk) {
      // Full local update if server said "ok"
      await paramsController.setUserParams(params);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Plante',
        restorationScopeId: 'app',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          primarySwatch: ColorsPlante.primaryMaterial,
          accentColor: ColorsPlante.primary,
          unselectedWidgetColor: ColorsPlante.grey,
          fontFamily: 'Poppins',
        ),
        home:
        AnimatedSwitcher(duration: DURATION_DEFAULT, child: _mainWidget()),
        navigatorObservers: [GetIt.I.get<RouteObserver<ModalRoute>>()]);
  }

  Widget _mainWidget() {
    if (_allRequiredUserParamsFilled()) {
      return const MainPage();
    }
    if (_userParams != null) {
      return InitUserPage(_userParams!, _onUserParamsSpecified);
    }
    return ExternalAuthPage(_onUserParamsSpecified);
  }

  bool _allRequiredUserParamsFilled() {
    if (_userParams == null) {
      return false;
    }
    if ((_userParams?.name ?? '').length < InitUserPage.MIN_NAME_LENGTH ||
        _userParams!.eatsMilk == null ||
        _userParams!.eatsEggs == null ||
        _userParams!.eatsHoney == null) {
      return false;
    }
    return true;
  }

  @override
  void onUserParamsUpdate(UserParams? userParams) {
    // Will reset screen to ExternalAuthPage if user params are wiped
    setState(() {
      _userParams = userParams;
    });
  }
}

class _AppForegroundDetector extends WidgetsBindingObserver {
  final Function() foregroundCallback;

  _AppForegroundDetector(this.foregroundCallback);

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    Log.i('didChangeAppLifecycleState, state: $state');
    if (state == AppLifecycleState.resumed) {
      await foregroundCallback.call();
    }
  }
}
