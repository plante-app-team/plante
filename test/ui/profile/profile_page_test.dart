import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/settings.dart';
import 'package:plante/lang/sys_lang_code_holder.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/profile/edit_profile_page.dart';
import 'package:plante/ui/profile/profile_page.dart';
import 'package:plante/ui/settings/settings_page.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
  late FakeUserParamsController userParamsController;
  late FakeUserAvatarManager userAvatarManager;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());

    userParamsController = FakeUserParamsController();
    userAvatarManager = FakeUserAvatarManager();

    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    GetIt.I.registerSingleton<UserAvatarManager>(userAvatarManager);
    GetIt.I.registerSingleton<Settings>(Settings());
    GetIt.I
        .registerSingleton<SysLangCodeHolder>(SysLangCodeHolder.inited('en'));
  });

  testWidgets('filled profile', (WidgetTester tester) async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = 'Bob Kelso'
      ..selfDescription = 'Hello there!'
      ..hasAvatar = true));
    await userAvatarManager.updateUserAvatar(imagePath);

    await tester.superPump(const ProfilePage());
    expect(find.text('Bob Kelso'), findsOneWidget);
    expect(find.text('Hello there!'), findsOneWidget);
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('not filled profile', (WidgetTester tester) async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = null
      ..selfDescription = null
      ..hasAvatar = false));
    await userAvatarManager.deleteUserAvatar();

    await tester.superPump(const ProfilePage());
    expect(find.byType(UriImagePlante), findsNothing);
    // We mostly test that the widget does not crash
  });

  testWidgets('no user params at all', (WidgetTester tester) async {
    await userParamsController.setUserParams(null);
    await userAvatarManager.deleteUserAvatar();

    await tester.superPump(const ProfilePage());
    expect(find.byType(UriImagePlante), findsNothing);
    // We mostly test that the widget does not crash
  });

  testWidgets('user params in widget listen to updates',
      (WidgetTester tester) async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = null
      ..selfDescription = null));

    await tester.superPump(const ProfilePage());

    expect(find.text('Bob Kelso'), findsNothing);
    await userParamsController.setUserParams(userParamsController
        .cachedUserParams!
        .rebuild((e) => e.name = 'Bob Kelso'));
    await tester.pumpAndSettle();
    expect(find.text('Bob Kelso'), findsOneWidget);

    expect(find.text('Hello there'), findsNothing);
    await userParamsController.setUserParams(userParamsController
        .cachedUserParams!
        .rebuild((e) => e.selfDescription = 'Hello there'));
    await tester.pumpAndSettle();
    expect(find.text('Hello there'), findsOneWidget);
    expect(find.text('Bob Kelso'), findsOneWidget);
  });

  testWidgets('user avatar in widget listen to updates',
      (WidgetTester tester) async {
    await userAvatarManager.deleteUserAvatar();

    await tester.superPump(const ProfilePage());

    expect(find.byType(UriImagePlante), findsNothing);
    await userAvatarManager.updateUserAvatar(imagePath);
    await tester.pumpAndSettle();
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('edit profile click', (WidgetTester tester) async {
    await tester.superPump(const ProfilePage());

    expect(find.byType(EditProfilePage), findsNothing);
    await tester.superTap(find.byKey(const Key('edit_profile_button')));
    expect(find.byType(EditProfilePage), findsOneWidget);
  });

  testWidgets('settings click', (WidgetTester tester) async {
    await userParamsController
        .setUserParams(UserParams((e) => e.name = 'Bob Kelso'));
    await tester.superPump(const ProfilePage());

    expect(find.byType(SettingsPage), findsNothing);
    await tester.superTap(find.byKey(const Key('settings_button')));
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
