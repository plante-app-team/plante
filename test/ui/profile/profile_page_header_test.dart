import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/profile/edit_profile_page.dart';
import 'package:plante/ui/profile/profile_page.dart';
import 'package:plante/ui/settings/settings_page.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';
import 'profile_page_test_commons.dart';

void main() {
  late ProfilePageTestCommons commons;
  const avatarId = ProfilePageTestCommons.avatarId;
  final imagePath = ProfilePageTestCommons.imagePath;
  late FakeUserParamsController userParamsController;
  late FakeUserAvatarManager userAvatarManager;

  setUp(() async {
    commons = await ProfilePageTestCommons.create();
    userParamsController = commons.userParamsController;
    userAvatarManager = commons.userAvatarManager;
  });

  testWidgets('filled profile', (WidgetTester tester) async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = 'Bob Kelso'
      ..selfDescription = 'Hello there!'
      ..avatarId = avatarId));
    await userAvatarManager.updateUserAvatar(imagePath);

    await tester.superPump(ProfilePage());
    expect(find.text('Bob Kelso'), findsOneWidget);
    expect(find.text('Hello there!'), findsOneWidget);
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('not filled profile', (WidgetTester tester) async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = null
      ..selfDescription = null
      ..avatarId = null));
    await userAvatarManager.deleteUserAvatar();

    await tester.superPump(ProfilePage());
    expect(find.byType(UriImagePlante), findsNothing);
    // We mostly test that the widget does not crash
  });

  testWidgets('no user params at all', (WidgetTester tester) async {
    await userParamsController.setUserParams(null);
    await userAvatarManager.deleteUserAvatar();

    await tester.superPump(ProfilePage());
    expect(find.byType(UriImagePlante), findsNothing);
    // We mostly test that the widget does not crash
  });

  testWidgets('user params in widget listen to updates',
      (WidgetTester tester) async {
    await userParamsController.setUserParams(UserParams((e) => e
      ..name = null
      ..selfDescription = null));

    await tester.superPump(ProfilePage());

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

    await tester.superPump(ProfilePage());

    expect(find.byType(UriImagePlante), findsNothing);
    await userAvatarManager.updateUserAvatar(imagePath);
    await tester.pumpAndSettle();
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('edit profile click', (WidgetTester tester) async {
    await userParamsController
        .setUserParams(UserParams((e) => e.name = 'Bob Kelso'));
    await userAvatarManager.deleteUserAvatar();

    await tester.superPump(ProfilePage());

    expect(find.byType(EditProfilePage), findsNothing);
    await tester.superTap(find.byKey(const Key('edit_profile_button')));
    expect(find.byType(EditProfilePage), findsOneWidget);
  });

  testWidgets('settings click', (WidgetTester tester) async {
    await userParamsController
        .setUserParams(UserParams((e) => e.name = 'Bob Kelso'));
    await tester.superPump(ProfilePage());

    expect(find.byType(SettingsPage), findsNothing);
    await tester.superTap(find.byKey(const Key('settings_button')));
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
