import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/di.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/my_app_widget.dart';

bool? _crashOnErrors;

void main() {
  runZonedGuarded(mainImpl, (Object error, StackTrace stack) {
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
  Log.i('App start');

  initDI();
  final initialUserParams =
      await GetIt.I.get<UserParamsController>().getUserParams();

  setSystemUIOverlayStyle();

  _crashOnErrors = await GetIt.I.get<Settings>().crashOnErrors();

  runApp(RootRestorationScope(
      restorationId: 'root', child: MyAppWidget(initialUserParams)));
}

void onError(String text, dynamic? exception, StackTrace? stack) async {
  Log.e(text,
      ex: exception,
      stacktrace: stack,
      crashAllowed: false /* We'll crash ourselves */,
      crashlyticsAllowed: false /* We'll send the error ourselves */);
  if (kReleaseMode) {
    await FirebaseCrashlytics.instance
        .recordError(exception, stack, reason: text, fatal: true);
  }
  if (exception is FlutterError && exception.message.contains('RenderFlex')) {
    return;
  }
  if (_crashOnErrors ?? true) {
    exit(1);
  }
}
