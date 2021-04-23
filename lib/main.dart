import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/di.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/app_foreground_detector.dart';
import 'package:plante/ui/first_screen/external_auth_page.dart';
import 'package:plante/ui/first_screen/init_user_page.dart';
import 'package:plante/ui/main/main_page.dart';
import 'package:plante/model/user_params_controller.dart';

void main() {
  runZonedGuarded(
        mainImpl,
        (Object error, StackTrace stack) {
          onError(error.toString(), error, stack);
        });
}

void mainImpl() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    onError(details.toString(), details.exception, details.stack);
  };

  if (kReleaseMode) {
    await Firebase.initializeApp();
  }

  Log.init();
  Log.i("App start");

  initDI();
  final initialUserParams = await GetIt.I.get<UserParamsController>().getUserParams();

  setSystemUIOverlayStyle();

  runApp(RootRestorationScope(
      restorationId: 'root',
      child: MyApp(initialUserParams)));
}

void onError(String text, dynamic? exception, StackTrace? stack) async {
  Log.e(
      text,
      ex: exception,
      stacktrace: stack,
      crashAllowed: false /* We'll crash ourselves */,
      crashlyticsAllowed: false /* We'll send the error ourselves */);
  if (kReleaseMode) {
    await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: text,
        fatal: true);
  }
  exit(1);
}


class MyApp extends StatefulWidget {
  final UserParams? _initialUserParams;

  MyApp(this._initialUserParams);

  @override
  State<StatefulWidget> createState() => (_MyAppState(_initialUserParams));
}

class _MyAppState extends State<MyApp> implements UserParamsControllerObserver {
  UserParams? _initialUserParams;

  _MyAppState(this._initialUserParams) {
    GetIt.I.get<UserParamsController>().addObserver(this);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(AppForegroundDetector(() {
      setSystemUIOverlayStyle();
    }));
  }

  Future<bool> _onUserParamsSpecified(UserParams params) async {
    Log.i("MyApp._onUserParamsSpecified: $params");
    final paramsController = GetIt.I.get<UserParamsController>();

    // Update on backend
    final result = await GetIt.I.get<Backend>().updateUserParams(
        params, backendClientTokenOverride: params.backendClientToken);
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: _mainWidget(),
      navigatorObservers: [GetIt.I.get<RouteObserver<ModalRoute>>()]
    );
  }

  Widget _mainWidget() {
    if (_allRequiredUserParamsFilled()) {
      return MainPage();
    }
    if (_initialUserParams != null) {
      return InitUserPage(_initialUserParams!, _onUserParamsSpecified);
    }
    return ExternalAuthPage(_onUserParamsSpecified);
  }

  bool _allRequiredUserParamsFilled() {
    if (_initialUserParams == null) {
      return false;
    }
    if ((_initialUserParams?.name ?? "").length < InitUserPage.minNameLength
        || _initialUserParams!.eatsMilk == null
        || _initialUserParams!.eatsEggs == null
        || _initialUserParams!.eatsHoney == null) {
      return false;
    }
    return true;
  }

  @override
  void onUserParamsUpdate(UserParams? userParams) {
    // Will reset screen to ExternalAuthPage if user params are wiped
    setState(() {
      _initialUserParams = userParams;
    });
  }
}
