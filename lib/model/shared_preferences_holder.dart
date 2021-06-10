import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around [SharedPreferences.getInstance] mainly for testing purposes
class SharedPreferencesHolder {
  Future<SharedPreferences> get() => SharedPreferences.getInstance();
}
