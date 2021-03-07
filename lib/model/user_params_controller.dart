import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled_vegan_app/model/user_params.dart';

const PREF_USER_PARAMS_NAME = 'USER_PARAMS_NAME';
const PREF_USER_BIRTHDAY = 'PREF_USER_BIRTHDAY';
const PREF_USER_EATS_MILK = 'PREF_USER_EATS_MILK';
const PREF_USER_EATS_EGGS = 'PREF_USER_EATS_EGGS';
const PREF_USER_EATS_HONEY = 'PREF_USER_EATS_HONEY';

class UserParamsController {
  Future<UserParams?> getUserParams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(PREF_USER_PARAMS_NAME);
    final birthday = prefs.getInt(PREF_USER_BIRTHDAY);
    final eatsMilk = prefs.getBool(PREF_USER_EATS_MILK);
    final eatsEggs = prefs.getBool(PREF_USER_EATS_EGGS);
    final eatsHoney = prefs.getBool(PREF_USER_EATS_HONEY);
    if (name == null
        || birthday == null
        || eatsMilk == null
        || eatsEggs == null
        || eatsHoney == null) {
      return null;
    }
    return UserParams(name, birthday, eatsMilk, eatsEggs, eatsHoney);
  }

  Future<void> setUserParams(UserParams userParams) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREF_USER_PARAMS_NAME, userParams.name);
    await prefs.setInt(PREF_USER_BIRTHDAY, userParams.birthday);
    await prefs.setBool(PREF_USER_EATS_MILK, userParams.eatsMilk);
    await prefs.setBool(PREF_USER_EATS_EGGS, userParams.eatsEggs);
    await prefs.setBool(PREF_USER_EATS_HONEY, userParams.eatsHoney);
  }
}
