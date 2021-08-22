extension DateTimeExtensions on DateTime {
  DateTime plusYears(int years) {
    return DateTime(year + years, month, day, hour, minute, second, millisecond,
        microsecond);
  }

  DateTime minusYears(int years) {
    return plusYears(-years);
  }

  int get secondsSinceEpoch => (millisecondsSinceEpoch / 1000).round();
}

DateTime dateTimeFromSecondsSinceEpoch(int seconds) {
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}
