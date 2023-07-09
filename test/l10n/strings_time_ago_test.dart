import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/l10n/strings_time_ago.dart';

import '../widget_tester_extension.dart';

void main() {
  testWidgets('minutes and switch to hours', (WidgetTester tester) async {
    final context = await tester.createContext();

    // seconds
    expect(context.timeAgo(seconds: 59), equals('just now'));

    // minutes
    expect(context.timeAgo(minutes: 1), equals('1 minute ago'));
    for (int minute = 2; minute < 60; ++minute) {
      expect(context.timeAgo(minutes: minute), equals('$minute minutes ago'));
    }

    // hours
    expect(context.timeAgo(minutes: 60), equals('1 hour ago'));
  });

  testWidgets('hours and switch to days', (WidgetTester tester) async {
    final context = await tester.createContext();

    // hours
    expect(context.timeAgo(hours: 1), equals('1 hour ago'));
    for (int hours = 2; hours < 24; ++hours) {
      expect(context.timeAgo(hours: hours), equals('$hours hours ago'));
    }

    // days
    expect(context.timeAgo(hours: 24), equals('yesterday'));
  });

  testWidgets('days and switch to weeks', (WidgetTester tester) async {
    final context = await tester.createContext();

    // days
    expect(context.timeAgo(days: 1), equals('yesterday'));
    for (int days = 2; days < 7; ++days) {
      expect(context.timeAgo(days: days), equals('$days days ago'));
    }

    // weeks
    expect(context.timeAgo(days: 7), equals('1 week ago'));
  });

  testWidgets('weeks and switch to months', (WidgetTester tester) async {
    final context = await tester.createContext();

    // weeks
    for (int days = 7; days < 14; ++days) {
      expect(context.timeAgo(days: days), equals('1 week ago'));
    }
    for (int days = 14; days < 30; ++days) {
      expect(context.timeAgo(days: days), equals('${days ~/ 7} weeks ago'));
    }

    // months
    expect(context.timeAgo(days: 30), equals('1 month ago'));
  });

  testWidgets('months and switch to years', (WidgetTester tester) async {
    final context = await tester.createContext();

    // weeks
    for (int days = 30; days < 60; ++days) {
      expect(context.timeAgo(days: days), equals('1 month ago'));
    }
    for (int days = 60; days < 365; ++days) {
      expect(context.timeAgo(days: days), equals('${days ~/ 30} months ago'));
    }

    // years
    expect(context.timeAgo(days: 365), equals('1 year ago'));
  });

  testWidgets('years', (WidgetTester tester) async {
    final context = await tester.createContext();

    expect(context.timeAgo(days: 365), equals('1 year ago'));
    expect(context.timeAgo(days: 365 * 2), equals('2 years ago'));
    expect(context.timeAgo(days: 365 * 3), equals('3 years ago'));
  });
}

extension _WidgetTester on WidgetTester {
  Future<BuildContext> createContext() async =>
      await superPump(const SizedBox.shrink());
}

extension _BuildContext on BuildContext {
  String timeAgo(
      {int seconds = 0, int minutes = 0, int hours = 0, int days = 0}) {
    return strings.timeAgoFromDuration(
        Duration(seconds: seconds, minutes: minutes, hours: hours, days: days));
  }
}
