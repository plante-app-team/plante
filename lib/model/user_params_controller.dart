import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/shared_preferences_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

// WARNING: DO NOT REUSE SAME NAME FOR DIFFERENT TYPES
const PREF_USER_PARAMS_NAME = 'USER_PARAMS_NAME2';
const PREF_USER_PARAMS_SELF_DESCRIPTION = 'USER_PARAMS_SELF_DESCRIPTION';
const PREF_USER_PARAMS_GENDER = 'USER_PARAMS_GENDER2';
const PREF_USER_BIRTHDAY = 'PREF_USER_BIRTHDAY2';
const PREF_USER_ID_ON_BACKEND = 'USER_ID_ON_BACKEND2';
const PREF_USER_CLIENT_TOKEN_FOR_BACKEND =
    'PREF_USER_CLIENT_TOKEN_FOR_BACKEND2';
const PREF_USER_CLIENT_USER_GROUP = 'PREF_USER_CLIENT_USER_GROUP2';
const PREF_LANGS_PRIORITIZED = 'PREF_LANGS_PRIORITIZED';
const PREF_AVATAR_ID = 'PREF_AVATAR_ID';
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
    final selfDescription = prefs.getString(PREF_USER_PARAMS_SELF_DESCRIPTION);
    final genderStr = prefs.getString(PREF_USER_PARAMS_GENDER);
    final birthdayStr = prefs.getString(PREF_USER_BIRTHDAY);
    final backendId = prefs.getString(PREF_USER_ID_ON_BACKEND);
    final clientToken = prefs.getString(PREF_USER_CLIENT_TOKEN_FOR_BACKEND);
    final userGroup = prefs.getInt(PREF_USER_CLIENT_USER_GROUP);
    final langsPrioritized = prefs.getStringList(PREF_LANGS_PRIORITIZED);
    final avatarId = prefs.getString(PREF_AVATAR_ID);

    if (name == null &&
        genderStr == null &&
        birthdayStr == null &&
        backendId == null &&
        clientToken == null &&
        langsPrioritized == null) {
      return null;
    }

    if (backendId != null && !_crashlyticsInited && !isInTests() && !kIsWeb) {
      await FirebaseCrashlytics.instance.setUserIdentifier(backendId);
      _crashlyticsInited = true;
    }

    return UserParams((v) => v
      ..name = name
      ..selfDescription = selfDescription
      ..backendId = backendId
      ..backendClientToken = clientToken
      ..userGroup = userGroup
      ..langsPrioritized =
          langsPrioritized != null ? ListBuilder(langsPrioritized) : null
      ..avatarId = avatarId);
  }

  /// Same as [UserParamsController.getUserParams] but will work only
  /// if called not immediately after startup.
  UserParams? get cachedUserParams => _cachedUserParams;

  Future<void> setUserParams(UserParams? userParams) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (userParams == null) {
      await prefs.safeRemove(PREF_USER_PARAMS_NAME);
      await prefs.safeRemove(PREF_USER_PARAMS_SELF_DESCRIPTION);
      await prefs.safeRemove(PREF_USER_PARAMS_GENDER);
      await prefs.safeRemove(PREF_USER_BIRTHDAY);
      await prefs.safeRemove(PREF_USER_ID_ON_BACKEND);
      await prefs.safeRemove(PREF_USER_CLIENT_TOKEN_FOR_BACKEND);
      await prefs.safeRemove(PREF_USER_CLIENT_USER_GROUP);
      await prefs.safeRemove(PREF_LANGS_PRIORITIZED);
      await prefs.safeRemove(PREF_AVATAR_ID);
      _observers.forEach((obs) {
        obs.onUserParamsUpdate(null);
      });
      return;
    }

    if (userParams.name != null && userParams.name!.isNotEmpty) {
      await prefs.setString(PREF_USER_PARAMS_NAME, userParams.name!);
    } else {
      await prefs.safeRemove(PREF_USER_PARAMS_NAME);
    }

    if (userParams.selfDescription != null &&
        userParams.selfDescription!.isNotEmpty) {
      await prefs.setString(
          PREF_USER_PARAMS_SELF_DESCRIPTION, userParams.selfDescription!);
    } else {
      await prefs.safeRemove(PREF_USER_PARAMS_SELF_DESCRIPTION);
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

    if (userParams.langsPrioritized != null) {
      await prefs.setStringList(
          PREF_LANGS_PRIORITIZED, userParams.langsPrioritized!.toList());
    } else {
      await prefs.safeRemove(PREF_LANGS_PRIORITIZED);
    }

    if (userParams.avatarId != null) {
      await prefs.setString(PREF_AVATAR_ID, userParams.avatarId!);
    } else {
      await prefs.safeRemove(PREF_AVATAR_ID);
    }

    _cachedUserParams = userParams;
    _observers.forEach((obs) {
      obs.onUserParamsUpdate(userParams);
    });
  }
}
