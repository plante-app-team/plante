import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled_vegan_app/model/gender.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/ui/base/shared_preferences_extensions.dart';

const PREF_USER_PARAMS_NAME = 'USER_PARAMS_NAME';
const PREF_USER_PARAMS_GENDER = 'USER_PARAMS_GENDER';
const PREF_USER_BIRTHDAY = 'PREF_USER_BIRTHDAY';
const PREF_USER_EATS_MILK = 'PREF_USER_EATS_MILK';
const PREF_USER_EATS_EGGS = 'PREF_USER_EATS_EGGS';
const PREF_USER_EATS_HONEY = 'PREF_USER_EATS_HONEY';

class UserParamsController {
  Future<UserParams?> getUserParams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(PREF_USER_PARAMS_NAME);
    final genderStr = prefs.getString(PREF_USER_PARAMS_GENDER);
    final birthdayStr = prefs.getString(PREF_USER_BIRTHDAY);
    final eatsMilk = prefs.getBool(PREF_USER_EATS_MILK);
    final eatsEggs = prefs.getBool(PREF_USER_EATS_EGGS);
    final eatsHoney = prefs.getBool(PREF_USER_EATS_HONEY);
    if (name == null) {
      return null;
    }
    final DateTime? birthday;
    if (birthdayStr != null) {
      // TODO(https://trello.com/c/XWAE5UVB/): log warning if parsing failed
      birthday = DateTime.tryParse(birthdayStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      birthday = null;
    }
    final Gender? gender;
    if (genderStr == "M") {
      gender = Gender.MALE;
    } else if (genderStr == "F") {
      gender = Gender.FEMALE;
    } else {
      gender = null;
    }
    return UserParams(
        name,
        gender: gender,
        birthday: birthday,
        eatsMilk: eatsMilk,
        eatsEggs: eatsEggs,
        eatsHoney: eatsHoney);
  }

  Future<void> setUserParams(UserParams? userParams) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (userParams == null) {
      await prefs.safeRemove(PREF_USER_PARAMS_NAME);
      await prefs.safeRemove(PREF_USER_PARAMS_GENDER);
      await prefs.safeRemove(PREF_USER_BIRTHDAY);
      await prefs.safeRemove(PREF_USER_EATS_MILK);
      await prefs.safeRemove(PREF_USER_EATS_EGGS);
      await prefs.safeRemove(PREF_USER_EATS_HONEY);
      return;
    }

    await prefs.setString(PREF_USER_PARAMS_NAME, userParams.name);

    if (userParams.gender != null) {
      final String? genderStr;
      switch (userParams.gender) {
        case Gender.MALE:
          genderStr = "M";
          break;
        case Gender.FEMALE:
          genderStr = "F";
          break;
        default:
          // TODO(https://trello.com/c/XWAE5UVB/): report an error
          genderStr = null;
      }
      if (genderStr != null) {
        await prefs.setString(PREF_USER_PARAMS_GENDER, genderStr);
      } else {
        await prefs.safeRemove(PREF_USER_PARAMS_GENDER);
      }
    }

    if (userParams.birthday != null) {
      await prefs.setString(PREF_USER_BIRTHDAY, userParams.birthday.toString());
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
  }
}
