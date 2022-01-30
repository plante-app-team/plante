import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/first_screen/external_auth_page.dart';
import 'package:plante/ui/first_screen/init_user_page.dart';
import 'package:plante/ui/main/main_page.dart';
import 'package:plante/ui/profile/components/edit_user_data_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSwatch(primarySwatch: ColorsPlante.primaryMaterial);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Plante',
        restorationScopeId: 'app',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: _supportedLocales(),
        theme: ThemeData(
          unselectedWidgetColor: ColorsPlante.grey,
          toggleableActiveColor: ColorsPlante.primary,
          colorScheme: colorScheme.copyWith(primary: ColorsPlante.primary),
        ),
        home:
            AnimatedSwitcher(duration: DURATION_DEFAULT, child: _mainWidget()),
        navigatorObservers: [GetIt.I.get<RouteObserver<ModalRoute>>()]);
  }

  Iterable<Locale> _supportedLocales() {
    // We have to make English the default language
    final withoutEnglish =
        AppLocalizations.supportedLocales.where((e) => e.languageCode != 'en');
    return [const Locale('en')] + withoutEnglish.toList();
  }

  Widget _mainWidget() {
    if (_allRequiredUserParamsFilled()) {
      return const MainPage();
    }
    if (_userParams != null) {
      return const InitUserPage();
    }
    return const ExternalAuthPage();
  }

  bool _allRequiredUserParamsFilled() {
    if (_userParams == null) {
      return false;
    }
    if ((_userParams?.name ?? '').length < EditUserDataWidget.MIN_NAME_LENGTH ||
        _userParams!.langsPrioritized == null ||
        _userParams!.langsPrioritized!.isEmpty) {
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
