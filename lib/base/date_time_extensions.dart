extension DateTimeExtensions on DateTime {
  DateTime plusYears(int years) {
    return DateTime(
        this.year + years,
        this.month,
        this.day,
        this.hour,
        this.minute,
        this.second,
        this.millisecond,
        this.microsecond);
  }
  DateTime minusYears(int years) {
    return this.plusYears(-years);
  }
}
