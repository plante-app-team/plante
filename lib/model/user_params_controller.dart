import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:plante/base/base.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plante/model/gender.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/shared_preferences_extensions.dart';

// WARNING: DO NOT REUSE SAME NAME FOR DIFFERENT TYPES
const PREF_USER_PARAMS_NAME = 'USER_PARAMS_NAME2';
const PREF_USER_PARAMS_GENDER = 'USER_PARAMS_GENDER2';
const PREF_USER_BIRTHDAY = 'PREF_USER_BIRTHDAY2';
const PREF_USER_EATS_MILK = 'PREF_USER_EATS_MILK2';
const PREF_USER_EATS_EGGS = 'PREF_USER_EATS_EGGS2';
const PREF_USER_EATS_HONEY = 'PREF_USER_EATS_HONEY2';
const PREF_USER_ID_ON_BACKEND = 'USER_ID_ON_BACKEND2';
const PREF_USER_CLIENT_TOKEN_FOR_BACKEND =
    'PREF_USER_CLIENT_TOKEN_FOR_BACKEND2';
const PREF_USER_CLIENT_USER_GROUP = 'PREF_USER_CLIENT_USER_GROUP2';
// WARNING: DO NOT REUSE SAME NAME FOR DIFFERENT TYPES

class UserParamsControllerObserver {
  void onUserParamsUpdate(UserParams? userParams) {}
}

class UserParamsController {
  late UserParams? _cachedUserParams;
  bool _crashlyticsInited = false;
  final _observers = <UserParamsControllerObserver>[];

  UserParamsController() {
    () async {
      _cachedUserParams = await getUserParams();
    }.call();
  }

  void addObserver(UserParamsControllerObserver observer) =>
      _observers.add(observer);
  void removeObserver(UserParamsControllerObserver observer) =>
      _observers.remove(observer);

  Future<UserParams?> getUserParams() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(PREF_USER_PARAMS_NAME);
    final genderStr = prefs.getString(PREF_USER_PARAMS_GENDER);
    final birthdayStr = prefs.getString(PREF_USER_BIRTHDAY);
    final eatsMilk = prefs.getBool(PREF_USER_EATS_MILK);
    final eatsEggs = prefs.getBool(PREF_USER_EATS_EGGS);
    final eatsHoney = prefs.getBool(PREF_USER_EATS_HONEY);
    final backendId = prefs.getString(PREF_USER_ID_ON_BACKEND);
    final clientToken = prefs.getString(PREF_USER_CLIENT_TOKEN_FOR_BACKEND);
    final userGroup = prefs.getInt(PREF_USER_CLIENT_USER_GROUP);

    if (name == null &&
        genderStr == null &&
        birthdayStr == null &&
        eatsMilk == null &&
        eatsEggs == null &&
        eatsHoney == null &&
        backendId == null &&
        clientToken == null) {
      return null;
    }

    if (backendId != null && !_crashlyticsInited && !isInTests()) {
      await FirebaseCrashlytics.instance.setUserIdentifier(backendId);
      _crashlyticsInited = true;
    }

    return UserParams((v) => v
      ..name = name
      ..backendId = backendId
      ..backendClientToken = clientToken
      ..genderStr = genderStr
      ..birthdayStr = birthdayStr
      ..eatsMilk = eatsMilk
      ..eatsEggs = eatsEggs
      ..eatsHoney = eatsHoney
      ..userGroup = userGroup);
  }

  /// Same as [UserParamsController.getUserParams] but will work only
  /// if called not immediately after startup.
  UserParams? get cachedUserParams => _cachedUserParams;

  Future<void> setUserParams(UserParams? userParams) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (userParams == null) {
      await prefs.safeRemove(PREF_USER_PARAMS_NAME);
      await prefs.safeRemove(PREF_USER_PARAMS_GENDER);
      await prefs.safeRemove(PREF_USER_BIRTHDAY);
      await prefs.safeRemove(PREF_USER_EATS_MILK);
      await prefs.safeRemove(PREF_USER_EATS_EGGS);
      await prefs.safeRemove(PREF_USER_EATS_HONEY);
      await prefs.safeRemove(PREF_USER_ID_ON_BACKEND);
      await prefs.safeRemove(PREF_USER_CLIENT_TOKEN_FOR_BACKEND);
      await prefs.safeRemove(PREF_USER_CLIENT_USER_GROUP);
      _observers.forEach((obs) {
        obs.onUserParamsUpdate(null);
      });
      return;
    }

    if (userParams.gender != null) {
      await prefs.setString(PREF_USER_PARAMS_GENDER, userParams.gender!.name);
    } else {
      await prefs.safeRemove(PREF_USER_PARAMS_GENDER);
    }

    if (userParams.name != null && userParams.name!.isNotEmpty) {
      await prefs.setString(PREF_USER_PARAMS_NAME, userParams.name!);
    } else {
      await prefs.safeRemove(PREF_USER_PARAMS_NAME);
    }

    if (userParams.birthday != null) {
      await prefs.setString(PREF_USER_BIRTHDAY, userParams.birthdayStr!);
    } else {
      await prefs.safeRemove(PREF_USER_BIRTHDAY);
    }

    if (userParams.eatsMilk != null) {
      await prefs.setBool(PREF_USER_EATS_MILK, userParams.eatsMilk!);
    } else {
      await prefs.safeRemove(PREF_USER_EATS_MILK);
    }

    if (userParams.eatsEggs != null) {
      await prefs.setBool(PREF_USER_EATS_EGGS, userParams.eatsEggs!);
    } else {
      await prefs.safeRemove(PREF_USER_EATS_EGGS);
    }

    if (userParams.eatsHoney != null) {
      await prefs.setBool(PREF_USER_EATS_HONEY, userParams.eatsHoney!);
    } else {
      await prefs.safeRemove(PREF_USER_EATS_HONEY);
    }

    if (userParams.backendId != null) {
      await prefs.setString(PREF_USER_ID_ON_BACKEND, userParams.backendId!);
    } else {
      await prefs.safeRemove(PREF_USER_ID_ON_BACKEND);
    }

    if (userParams.backendClientToken != null) {
      await prefs.setString(
          PREF_USER_CLIENT_TOKEN_FOR_BACKEND, userParams.backendClientToken!);
    } else {
      await prefs.safeRemove(PREF_USER_CLIENT_TOKEN_FOR_BACKEND);
    }

    if (userParams.userGroup != null) {
      await prefs.setInt(PREF_USER_CLIENT_USER_GROUP, userParams.userGroup!);
    } else {
      await prefs.safeRemove(PREF_USER_CLIENT_USER_GROUP);
    }
    _cachedUserParams = userParams;
    _observers.forEach((obs) {
      obs.onUserParamsUpdate(userParams);
    });
  }
}
