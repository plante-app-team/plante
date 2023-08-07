import 'dart:async';
import 'dart:convert';

import 'package:plante/logging/log.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/cmds/mobile_app_config_cmd.dart';
import 'package:plante/outside/backend/mobile_app_config.dart';

abstract class MobileAppConfigManagerObserver {
  void onMobileAppConfigChange(MobileAppConfig? config);
}

class MobileAppConfigManager implements UserParamsControllerObserver {
  static const PREF_MOBILE_APP_CONFIG = 'MOBILE_APP_CONFIG';
  final Backend _backend;
  final UserParamsController _userParamsController;
  final SharedPreferencesHolder _prefsHolder;

  final _observers = <MobileAppConfigManagerObserver>[];

  final _initCompleter = Completer<void>();
  Future<void> get initFuture => _initCompleter.future;
  MobileAppConfig? _config;

  MobileAppConfigManager(
      this._backend, this._userParamsController, this._prefsHolder) {
    _initAsync();
  }

  void _initAsync() async {
    await _initFromPrefs();
    await _fetchRemoteConfig();
    _userParamsController.addObserver(this);
  }

  Future<void> _initFromPrefs() async {
    final prefs = await _prefsHolder.get();
    final configStr = prefs.getString(PREF_MOBILE_APP_CONFIG);
    if (configStr != null) {
      try {
        _config = MobileAppConfig.fromJson(jsonDecode(configStr));
      } catch (e) {
        Log.w('Mobile App Config decode error', ex: e);
        await prefs.remove(PREF_MOBILE_APP_CONFIG);
      }
    }
    _initCompleter.complete();
  }

  Future<void> _fetchRemoteConfig() async {
    final configRes = await _backend.mobileAppConfig();
    if (configRes.isErr) {
      return;
    }
    final newConfig = configRes.unwrap();
    if (newConfig != _config) {
      _config = newConfig;
      final prefs = await _prefsHolder.get();
      await prefs.setString(
          PREF_MOBILE_APP_CONFIG, jsonEncode(newConfig.toJson()));
      _notifyObservers();
    }
  }

  @override
  void onUserParamsUpdate(UserParams? userParams) {
    if (userParams != null && _config == null) {
      _fetchRemoteConfig();
    } else if (userParams == null) {
      _deleteConfig();
    }
  }

  void _deleteConfig() async {
    if (_config == null) {
      return;
    }
    final prefs = await _prefsHolder.get();
    await prefs.remove(PREF_MOBILE_APP_CONFIG);
    _config = null;
    _notifyObservers();
  }

  void _notifyObservers() {
    _observers.forEach((e) => e.onMobileAppConfigChange(_config));
  }

  void addObserver(MobileAppConfigManagerObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(MobileAppConfigManagerObserver observer) {
    _observers.remove(observer);
  }

  Future<MobileAppConfig?> getConfig() async {
    await initFuture;
    return _config;
  }
}
