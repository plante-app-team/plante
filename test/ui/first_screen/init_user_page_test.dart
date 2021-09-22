import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/lang_code.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/ui/first_screen/init_user_page.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  late FakeUserParamsController userParamsController;
  late FakeUserLangsManager userLangsManager;
  late MockBackend backend;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());
    GetIt.I.registerSingleton<SysLangCodeHolder>(SysLangCodeHolder());

    userParamsController = FakeUserParamsController();
    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    userLangsManager = FakeUserLangsManager([LangCode.en],
        fakeUserParamsController: userParamsController, auto: true);
    GetIt.I.registerSingleton<UserLangsManager>(userLangsManager);
    backend = MockBackend();
    GetIt.I.registerSingleton<Backend>(backend);

    when(backend.updateUserParams(any)).thenAnswer((_) async => Ok(true));
  });

  testWidgets('Can fill all data and get user params',
      (WidgetTester tester) async {
    final context = await tester.superPump(const InitUserPage());

    await tester.enterText(find.byKey(const Key('name')), 'Bob');

    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester.tap(find.text(LangCode.be.localize(context)));
    await tester.pumpAndSettle();

    expect(await userParamsController.getUserParams(), isNull);

    await tester
        .tap(find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    final expectedParams = UserParams((v) => v
      ..name = 'Bob'
      ..langsPrioritized.addAll([LangCode.en, LangCode.be].map((e) => e.name)));
    expect(await userParamsController.getUserParams(), equals(expectedParams));

    final expectedLangs = UserLangs((e) => e
      ..auto = false
      ..sysLang = LangCode.en
      ..langs.addAll([LangCode.en, LangCode.be]));
    expect(await userLangsManager.getUserLangs(), equals(expectedLangs));
  });

  testWidgets('Uses initial user name', (WidgetTester tester) async {
    final initialParams = UserParams((v) => v.name = 'Nora');
    await userParamsController.setUserParams(initialParams);
    final context = await tester.superPump(const InitUserPage());

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
      ..langsPrioritized.add(LangCode.en.name));
    expect(await userParamsController.getUserParams(), equals(expectedParams));
  });

  testWidgets("Doesn't allow too short names", (WidgetTester tester) async {
    final context = await tester.superPump(const InitUserPage());

    await tester.enterText(find.byKey(const Key('name')), 'Bo');

    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    // Expect next screen to not be open even after
    // "Next" tap (because name is too short)
    expect(find.text(context.strings.init_user_page_langs_explanation), findsNothing);
  });

  testWidgets('Langs saving error', (WidgetTester tester) async {
    userLangsManager.savingLangsError = UserLangsManagerError.NETWORK;

    final context = await tester.superPump(const InitUserPage());

    await tester.enterText(find.byKey(const Key('name')), 'Bob');

    await tester.pumpAndSettle();
    await tester
        .tap(find.text(context.strings.init_user_page_next_button_title));
    await tester.pumpAndSettle();

    await tester.tap(find.text(LangCode.be.localize(context)));
    await tester.pumpAndSettle();

    await tester
        .tap(find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    // Nope, network error
    expect(
        (await userParamsController.getUserParams())!.langsPrioritized, isNull);
    expect(find.text(context.strings.global_network_error), findsWidgets);
    var expectedLangs = UserLangs((e) => e
      ..auto = true
      ..sysLang = LangCode.en
      ..langs.addAll([LangCode.en]));
    expect(await userLangsManager.getUserLangs(), equals(expectedLangs));

    // Network is back!
    userLangsManager.savingLangsError = null;

    await tester
        .tap(find.text(context.strings.init_user_page_done_button_title));
    await tester.pumpAndSettle();

    expectedLangs = UserLangs((e) => e
      ..auto = false
      ..sysLang = LangCode.en
      ..langs.addAll([LangCode.en, LangCode.be]));
    expect(await userLangsManager.getUserLangs(), equals(expectedLangs));

    final expectedParams = UserParams((v) => v
      ..name = 'Bob'
      ..langsPrioritized.addAll(expectedLangs.langs.map((e) => e.name)));
    expect(await userParamsController.getUserParams(), equals(expectedParams));
  });
}
