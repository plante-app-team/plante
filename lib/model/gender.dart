import 'package:plante/base/log.dart';

enum Gender { MALE, FEMALE }

extension GenderExtension on Gender {
  String get name {
    switch (this) {
      case Gender.MALE:
        return 'male';
      case Gender.FEMALE:
        return 'female';
      default:
        throw Exception('Unhandled item: $this');
    }
  }
}

Gender? genderFromGenderName(String genderName) {
  switch (genderName) {
    case 'male':
      return Gender.MALE;
    case 'female':
      return Gender.FEMALE;
    default:
      Log.w('Unknown gender name: $genderName');
      return null;
  }
}
