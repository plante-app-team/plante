extension DateTimeExtensions on DateTime {
  DateTime plusYears(int years) {
    return DateTime(year + years, month, day, hour, minute, second, millisecond,
        microsecond);
  }

  DateTime minusYears(int years) {
    return plusYears(-years);
  }
}
