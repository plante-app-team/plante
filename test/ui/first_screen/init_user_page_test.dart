import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:untitled_vegan_app/model/gender.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/ui/first_screen/init_user_page.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '../../widget_tester_extension.dart';

void main() {
  testWidgets("Can fill all data and get user params", (WidgetTester tester) async {
    UserParams? resultParams;
    final resultParamsCallback = (UserParams params) {
      resultParams = params;
    };
    final context = await tester.superPump(InitUserPage(null, resultParamsCallback));

    await tester.enterText(
        find.byKey(Key("name")),
        'Bob');
    await tester.enterText(
        find.byKey(Key("birthday")),
        '20.07.1993');
    await tester.tap(
        find.text(context.strings.init_user_page_gender_short_male));

    await tester.pumpAndSettle();
    await tester.tap(
        find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester.tap(
        find.text(context.strings.init_user_page_i_eat_honey));
    await tester.pumpAndSettle();

    expect(resultParams, equals(null));
    await tester.tap(
        find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    final expectedParams = UserParams(
      "Bob",
      gender: Gender.MALE,
      birthday: DateFormat('dd.MM.yyyy').parse("20.07.1993"),
      eatsMilk: false,
      eatsEggs: false,
      eatsHoney: true);
    expect(resultParams, equals(expectedParams));
  });

  testWidgets("Allows to not fill gender and birthday", (WidgetTester tester) async {
    UserParams? resultParams;
    final resultParamsCallback = (UserParams params) {
      resultParams = params;
    };
    final context = await tester.superPump(InitUserPage(null, resultParamsCallback));

    await tester.enterText(
        find.byKey(Key("name")),
        'Bob');

    await tester.pumpAndSettle();
    await tester.tap(
        find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester.tap(
        find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    final expectedParams = UserParams(
        "Bob",
        gender: null,
        birthday: null,
        eatsMilk: false,
        eatsEggs: false,
        eatsHoney: false);
    expect(resultParams, equals(expectedParams));
  });

  testWidgets("Uses initial user name", (WidgetTester tester) async {
    UserParams? resultParams;
    final resultParamsCallback = (UserParams params) {
      resultParams = params;
    };
    final initialParams = UserParams("Nora");
    final context = await tester.superPump(InitUserPage(initialParams, resultParamsCallback));

    await tester.pumpAndSettle();
    await tester.tap(
        find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();
    await tester.tap(
        find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    final expectedParams = UserParams(
        "Nora",
        gender: null,
        birthday: null,
        eatsMilk: false,
        eatsEggs: false,
        eatsHoney: false);
    expect(resultParams, equals(expectedParams));
  });

  testWidgets("Doesn't allow too short names", (WidgetTester tester) async {
    final resultParamsCallback = (UserParams params) {};
    final context = await tester.superPump(InitUserPage(null, resultParamsCallback));

    await tester.enterText(
        find.byKey(Key("name")),
        'Bo');

    await tester.pumpAndSettle();
    await tester.tap(
        find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    // Expect next screen to not be open even after
    // "Next" tap (because name is too short)
    expect(find.text(context.strings.init_user_page_i_eat_honey), findsNothing);
  });

  testWidgets("Doesn't allow invalid birthday", (WidgetTester tester) async {
    final resultParamsCallback = (UserParams params) {};
    final context = await tester.superPump(InitUserPage(null, resultParamsCallback));

    await tester.enterText(
        find.byKey(Key("name")),
        'Bob');
    await tester.enterText(
        find.byKey(Key("birthday")),
        '20.07');

    await tester.pumpAndSettle();
    await tester.tap(
        find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    // Expect next screen to not be open even after
    // "Next" tap (because birthday is invalid)
    expect(find.text(context.strings.init_user_page_i_eat_honey), findsNothing);
  });
}