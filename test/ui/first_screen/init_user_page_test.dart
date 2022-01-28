import 'dart:io';

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
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/first_screen/init_user_page.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_langs_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  const avatarId = FakeUserAvatarManager.DEFAULT_AVATAR_ID;
  late FakeUserParamsController userParamsController;
  late FakeUserLangsManager userLangsManager;
  late MockBackend backend;
  late FakeUserAvatarManager userAvatarManager;

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
    userAvatarManager = FakeUserAvatarManager(userParamsController);
    GetIt.I.registerSingleton<UserAvatarManager>(userAvatarManager);

    when(backend.updateUserParams(any)).thenAnswer((_) async => Ok(true));
  });

  testWidgets('can fill all data and get user params',
      (WidgetTester tester) async {
    // Avatar selection will be successful
    final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);

    final context = await tester.superPump(const InitUserPage());

    await tester.superEnterText(find.byKey(const Key('name_input')), 'Bob');
    await tester.superTap(find.byKey(const Key('change_avatar_button')));

    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));

    await tester.superTap(find.text(LangCode.be.localize(context)));

    expect(await userParamsController.getUserParams(), isNull);
    expect(await userAvatarManager.userAvatarUri(), isNull);
    expect(
        await userLangsManager.getUserLangs(),
        equals(UserLangs((e) => e
          ..auto = true
          ..sysLang = LangCode.en
          ..langs.addAll([LangCode.en]))));

    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    final expectedParams = UserParams((v) => v
      ..name = 'Bob'
      ..langsPrioritized.addAll([LangCode.en, LangCode.be].map((e) => e.name))
      ..avatarId = avatarId);
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    expect(await userAvatarManager.userAvatarUri(), imagePath);
    expect(
        await userLangsManager.getUserLangs(),
        equals(UserLangs((e) => e
          ..auto = false
          ..sysLang = LangCode.en
          ..langs.addAll([LangCode.en, LangCode.be]))));
  });

  testWidgets('can set and then delete user avatar',
      (WidgetTester tester) async {
    // Avatar selection will be successful
    final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);

    final context = await tester.superPump(const InitUserPage());

    await tester.superEnterText(find.byKey(const Key('name_input')), 'Bob');

    expect(find.byType(UriImagePlante), findsNothing);
    await tester.superTap(find.byKey(const Key('change_avatar_button')));
    expect(find.byType(UriImagePlante), findsOneWidget);
    await tester.superTap(
        find.text(context.strings.edit_user_data_widget_avatar_delete));
    expect(find.byType(UriImagePlante), findsNothing);

    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));
    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    expect(await userAvatarManager.userAvatarUri(), isNull);
    final expectedParams = UserParams((v) => v
      ..name = 'Bob'
      ..langsPrioritized.addAll([LangCode.en].map((e) => e.name))
      ..avatarId = null);
    expect(await userParamsController.getUserParams(), equals(expectedParams));
  });

  testWidgets('user avatar not set if avatar selection canceled by user',
      (WidgetTester tester) async {
    // FakeUserAvatarManager will act as if the user hasn't selected any avatar
    userAvatarManager.setSelectedGalleryImage_testing(null);

    final context = await tester.superPump(const InitUserPage());
    await tester.superEnterText(find.byKey(const Key('name_input')), 'Bob');

    // We expect the user to be asked to change the avatar
    expect(userAvatarManager.askUserToSelectImageFromGallery_callsCount(),
        equals(0));
    await tester.superTap(find.byKey(const Key('change_avatar_button')));
    expect(userAvatarManager.askUserToSelectImageFromGallery_callsCount(),
        equals(1));

    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));
    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    // No avatar is expected to be set
    expect(await userAvatarManager.userAvatarUri(), null);
    expect(
        await userParamsController.getUserParams(),
        equals(UserParams((v) => v
          ..name = 'Bob'
          ..langsPrioritized.addAll([LangCode.en].map((e) => e.name))
          ..avatarId = null)));
  });

  testWidgets('user avatar not set if avatar selection not started by user',
      (WidgetTester tester) async {
    // IF the user will start avatar selection, it will be successful
    final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);

    final context = await tester.superPump(const InitUserPage());
    await tester.superEnterText(find.byKey(const Key('name_input')), 'Bob');

    // NOTE: the user does not click the "change avatar" button:
    // await tester.superTap(find.byKey(const Key('change_avatar_button')));

    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));
    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    // No avatar is expected to be set
    expect(await userAvatarManager.userAvatarUri(), null);
    expect(
        await userParamsController.getUserParams(),
        equals(UserParams((v) => v
          ..name = 'Bob'
          ..langsPrioritized.addAll([LangCode.en].map((e) => e.name))
          ..avatarId = null)));

    // The user was not asked to choose an image from the gallery
    expect(userAvatarManager.askUserToSelectImageFromGallery_callsCount(),
        equals(0));
  });

  testWidgets('uses initial user name and avatar', (WidgetTester tester) async {
    final initialParams = UserParams((v) => v
      ..name = 'Nora'
      ..avatarId = avatarId);
    await userParamsController.setUserParams(initialParams);

    final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
    await userAvatarManager.updateUserAvatar(imagePath);

    final context = await tester.superPump(const InitUserPage());
    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));
    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    final expectedParams = UserParams((v) => v
      ..name = 'Nora'
      ..langsPrioritized.add(LangCode.en.name)
      ..avatarId = avatarId);
    expect(await userParamsController.getUserParams(), equals(expectedParams));

    expect(userAvatarManager.askUserToSelectImageFromGallery_callsCount(),
        equals(0));
    expect(await userAvatarManager.userAvatarUri(), equals(imagePath));
  });

  testWidgets('can delete preset user avatar', (WidgetTester tester) async {
    final initialParams = UserParams((v) => v
      ..name = 'Nora'
      ..avatarId = avatarId);
    await userParamsController.setUserParams(initialParams);

    final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
    await userAvatarManager.updateUserAvatar(imagePath);

    final context = await tester.superPump(const InitUserPage());
    await tester.superTap(
        find.text(context.strings.edit_user_data_widget_avatar_delete));
    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));
    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    final expectedParams = UserParams((v) => v
      ..name = 'Nora'
      ..langsPrioritized.add(LangCode.en.name)
      ..avatarId = null);
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    expect(await userAvatarManager.userAvatarUri(), isNull);
  });

  testWidgets("doesn't allow too short names", (WidgetTester tester) async {
    final context = await tester.superPump(const InitUserPage());
    await tester.superEnterText(find.byKey(const Key('name_input')), 'Bo');
    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));

    // Expect next screen to not be open even after
    // "Next" tap (because name is too short)
    expect(find.text(context.strings.init_user_page_langs_explanation),
        findsNothing);
  });

  testWidgets('langs saving error', (WidgetTester tester) async {
    userLangsManager.savingLangsError = UserLangsManagerError.NETWORK;

    final context = await tester.superPump(const InitUserPage());

    await tester.superEnterText(find.byKey(const Key('name_input')), 'Bob');
    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));

    await tester.superTap(find.text(LangCode.be.localize(context)));
    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

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
        .superTap(find.text(context.strings.init_user_page_done_button_title));

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

  testWidgets('avatar saving error', (WidgetTester tester) async {
    // Avatar selection will be successful
    final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);
    // But sending the avatar to the backend will end with failures
    userAvatarManager.setUpdateUserAvatarError_testing(BackendError.other());

    final context = await tester.superPump(const InitUserPage());

    await tester.superEnterText(find.byKey(const Key('name_input')), 'Bob');
    await tester.superTap(find.byKey(const Key('change_avatar_button')));
    await tester
        .superTap(find.text(context.strings.init_user_page_next_button_title));
    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    // Nope, backend error
    expect(await userAvatarManager.userAvatarUri(), isNull);
    expect(
        find.text(context.strings.global_something_went_wrong), findsWidgets);

    // Backend is ok now!
    userAvatarManager.setUpdateUserAvatarError_testing(null);

    await tester
        .superTap(find.text(context.strings.init_user_page_done_button_title));

    expect(await userAvatarManager.userAvatarUri(), imagePath);
    final expectedParams = UserParams((v) => v
      ..name = 'Bob'
      ..langsPrioritized.addAll([LangCode.en.name])
      ..avatarId = avatarId);
    expect(await userParamsController.getUserParams(), equals(expectedParams));
  });
}
