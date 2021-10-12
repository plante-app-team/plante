import 'dart:async';
import 'dart:isolate';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/di.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/my_app_widget.dart';

import 'base/base.dart';

void main() {
  runZonedGuarded(mainImpl, (Object error, StackTrace stack) {
    Log.e(error.toString(), ex: error, stacktrace: stack, crashAllowed: false);
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

void mainImpl() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(kReleaseMode);

  FlutterError.onError = (FlutterErrorDetails details) {
    Log.e('FE: ${details.toString()}',
        ex: details.exception, stacktrace: details.stack, crashAllowed: false);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  Isolate.current.addErrorListener(RawReceivePort((pair) async {
    final List<dynamic> errorAndStacktrace = pair as List<dynamic>;
    final error = errorAndStacktrace.first;
    final stack = errorAndStacktrace.last as StackTrace?;
    Log.e('IE: ${error.toString()}',
        ex: error, stacktrace: stack, crashAllowed: false);
    await FirebaseCrashlytics.instance.recordError(error, stack);
  }).sendPort);

  Log.init();
  Log.i('App start');

  initDI();
  final initialUserParams =
      await GetIt.I.get<UserParamsController>().getUserParams();

  setSystemUIOverlayStyle();

  runApp(MyAppWidget(initialUserParams));
}
