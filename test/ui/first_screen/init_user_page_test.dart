import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/first_screen/init_user_page.dart';
import 'package:plante/l10n/strings.dart';

import '../../common_mocks.dart';
import '../../common_mocks.mocks.dart';
import '../../fake_analytics.dart';
import '../../widget_tester_extension.dart';

void main() {
  late MockUserLangsManager userLangsManager;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());
    GetIt.I.registerSingleton<SysLangCodeHolder>(SysLangCodeHolder());
    userLangsManager = mockUserLangsManagerWith(LangCode.en);
    GetIt.I.registerSingleton<UserLangsManager>(userLangsManager);
  });

  testWidgets('Can fill all data and get user params',
      (WidgetTester tester) async {
    UserParams? resultParams;
    final resultParamsCallback = (UserParams params) async {
      resultParams = params;
      return true;
    };
    final context = await tester
        .superPump(InitUserPage(UserParams(), resultParamsCallback));

    await tester.enterText(find.byKey(const Key('name')), 'Bob');

    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.init_user_page_i_eat_honey));
    await tester.pumpAndSettle();

    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester.tap(find.text(LangCode.be.localize(context)));
    await tester.pumpAndSettle();

    expect(resultParams, equals(null));
    verifyNever(userLangsManager.setManualUserLangs(any));

    await tester
        .tap(find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    final expectedParams = UserParams((v) => v
      ..name = 'Bob'
      ..eatsMilk = false
      ..eatsEggs = false
      ..eatsHoney = true);
    expect(resultParams, equals(expectedParams));

    final expectedLangs = [LangCode.en, LangCode.be];
    verify(userLangsManager.setManualUserLangs(expectedLangs));
  });

  testWidgets('Uses initial user name', (WidgetTester tester) async {
    UserParams? resultParams;
    final resultParamsCallback = (UserParams params) async {
      resultParams = params;
      return true;
    };
    final initialParams = UserParams((v) => v.name = 'Nora');
    final context = await tester
        .superPump(InitUserPage(initialParams, resultParamsCallback));

    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester.tap(find.text(context.strings.init_user_page_im_vegan));
    await tester.pumpAndSettle();

    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();
    // We're ok with the system lang

    await tester
        .tap(find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    final expectedParams = UserParams((v) => v
      ..name = 'Nora'
      ..eatsMilk = false
      ..eatsEggs = false
      ..eatsHoney = false);
    expect(resultParams, equals(expectedParams));
  });

  testWidgets("Doesn't allow too short names", (WidgetTester tester) async {
    final resultParamsCallback = (UserParams params) async {
      return true;
    };
    final context = await tester
        .superPump(InitUserPage(UserParams(), resultParamsCallback));

    await tester.enterText(find.byKey(const Key('name')), 'Bo');

    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    // Expect next screen to not be open even after
    // "Next" tap (because name is too short)
    expect(find.text(context.strings.init_user_page_i_eat_honey), findsNothing);
  });

  testWidgets('Does not finish without vegan or vegetarian selection',
      (WidgetTester tester) async {
    final initialParams = UserParams((v) => v.name = 'Nora');
    final context =
        await tester.superPump(InitUserPage(initialParams, (_) async => true));

    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    // Expect next screen to not be open even after
    // "Next" tap (because veg-selection is not made)
    expect(find.text(context.strings.init_user_page_langs_explanation),
        findsNothing);
  });
}
