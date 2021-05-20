import 'dart:async';
import 'dart:isolate';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/di.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/my_app_widget.dart';

void main() {
  runZonedGuarded(mainImpl, (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

void mainImpl() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(kReleaseMode);

  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  Isolate.current.addErrorListener(RawReceivePort((pair) async {
    final List<dynamic> errorAndStacktrace = pair as List<dynamic>;
    await FirebaseCrashlytics.instance.recordError(
      errorAndStacktrace.first,
      errorAndStacktrace.last as StackTrace?,
    );
  }).sendPort);

  Log.init();
  Log.i('App start');

  initDI();
  final initialUserParams =
      await GetIt.I.get<UserParamsController>().getUserParams();

  setSystemUIOverlayStyle();

  runApp(RootRestorationScope(
      restorationId: 'root', child: MyAppWidget(initialUserParams)));
}
