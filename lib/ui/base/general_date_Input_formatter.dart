import 'package:flutter/services.dart';

/// General date input formatter.
///
/// **NOTE that the formatter partially LETS a lot of invalid dates in**, because a formatter
/// cannot verify a complex input format.
/// For example, if user types in "29.02", our formatter cannot know if the 29th day is ok
/// or not until the year is typed in. The formatter of course could then allow only years with
/// 29 days in february, but the user might get confused because they cannot type the year they want.
class GeneralDateInputFormatter extends TextInputFormatter {
  final int _startYear;
  final int _endYear;
  var _lastValidText = TextEditingValue();

  GeneralDateInputFormatter(this._startYear, this._endYear);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (_isValid(oldValue.text)) {
      _lastValidText = oldValue;
    }

    if (!newValue.composing.isCollapsed) {
      // Still composing
      return newValue;
    }

    if (!_isValid(newValue.text)) {
      return _lastValidText;
    }
    return newValue;
  }

  bool _isValid(String text) {
    // Empty str
    if (text.isEmpty) {
      return true;
    }

    final divider = '.';

    // Day
    final firstDividerIndex = text.indexOf(divider);
    final int dayEndIndex;
    if (firstDividerIndex != -1) {
      dayEndIndex = firstDividerIndex;
    } else {
      dayEndIndex = text.length;
    }

    if (!_isSectionValid(text, 0, dayEndIndex, 1, 31, divider)) {
      return false;
    }

    // Month
    if (_isLastSection(dayEndIndex, divider, text)) {
      // No month yet -
      return true;
    }
    final secondDividerIndex = text.indexOf(divider, dayEndIndex + 1);
    final int monthEndIndex;
    if (secondDividerIndex != -1) {
      monthEndIndex = secondDividerIndex;
    } else {
      monthEndIndex = text.length;
    }
    if (!_isSectionValid(
        text, dayEndIndex + 1, monthEndIndex, 1, 12, divider)) {
      return false;
    }

    // Year
    if (_isLastSection(monthEndIndex, divider, text)) {
      // No year yet
      return true;
    }
    if (!_isSectionValid(
        text, monthEndIndex + 1, text.length, _startYear, _endYear, divider)) {
      return false;
    }

    return true;
  }

  bool _isLastSection(int sectionEndIndex, String divider, String text) {
    // If we're at the end of
    return sectionEndIndex == text.length ||
        (text[sectionEndIndex] == divider &&
            sectionEndIndex + 1 == text.length);
  }

  bool _isSectionValid(
      String str, int start, int end, int min, int max, String divider) {
    // Empty
    if (end == start) {
      // Valid if there's no divider yet
      return end == str.length;
    }

    final substr = str.substring(start, end);
    // Definitely too big, even if it has zeroes at the start (e.g. '001').
    if (substr.length > max.toString().length) {
      return false;
    }

    // If divider is put already - let's check the value
    if (end != str.length && str[end] == divider) {
      final value = int.tryParse(substr);
      if (value == null) {
        return false;
      }
      return min <= value && value <= max;
    }

    // Let's check if the value IS or CAN be greater than min
    final maxStr = max.toString();
    var possibleMaxValueStr = substr;
    while (possibleMaxValueStr.length < maxStr.length) {
      possibleMaxValueStr += "9";
    }
    final possibleMaxValue = int.tryParse(possibleMaxValueStr);
    if (possibleMaxValue == null) {
      return false;
    }
    if (possibleMaxValue < min) {
      return false;
    }

    // Let's check that the value will be lesser than max if the user will finish typing it
    var possibleMinValue = int.tryParse(substr);
    if (possibleMinValue == null) {
      return false;
    }

    if (possibleMinValue != 0) {
      var possibleMinValueStr = possibleMinValue.toString();
      final minStr = min.toString();
      while (possibleMinValue! < min &&
          possibleMinValueStr.length < minStr.length) {
        possibleMinValue = int.parse(possibleMinValue.toString() + "0");
        possibleMinValueStr = possibleMinValue.toString();
      }
      if (max < possibleMinValue) {
        return false;
      }
    }

    return true;
  }
}
