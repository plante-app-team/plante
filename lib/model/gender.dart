enum Gender {
  MALE,
  FEMALE
}

extension GenderExtension on Gender {
  String get name {
    switch (this) {
      case Gender.MALE:
        return "male";
      case Gender.FEMALE:
        return "female";
      default:
        throw Exception("Unhandled item: $this");
    }
  }
}

Gender? genderFromGenderName(String genderName) {
  switch (genderName) {
    case "male":
      return Gender.MALE;
    case "female":
      return Gender.FEMALE;
    default:
      // TODO(https://trello.com/c/XWAE5UVB/): log warning
      return null;
  }
}
