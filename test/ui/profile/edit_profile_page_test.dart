import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/profile/edit_profile_page.dart';

import '../../common_mocks.mocks.dart';
import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_analytics.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  const avatarId = FakeUserAvatarManager.DEFAULT_AVATAR_ID;
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
  late FakeUserParamsController userParamsController;
  late FakeUserAvatarManager userAvatarManager;
  late MockBackend backend;

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<Analytics>(FakeAnalytics());

    userParamsController = FakeUserParamsController();
    userAvatarManager = FakeUserAvatarManager(userParamsController);
    backend = MockBackend();

    GetIt.I.registerSingleton<UserParamsController>(userParamsController);
    GetIt.I.registerSingleton<UserAvatarManager>(userAvatarManager);
    GetIt.I.registerSingleton<Backend>(backend);

    when(backend.updateUserParams(any)).thenAnswer((_) async => Ok(true));
  });

  testWidgets('with initial params', (WidgetTester tester) async {
    final initialUserParams = UserParams((e) => e
      ..name = 'Bob Kelso'
      ..selfDescription = 'Hello there!'
      ..avatarId = avatarId);
    final initialAvatar = imagePath;
    await userParamsController.setUserParams(initialUserParams);
    await userAvatarManager.updateUserAvatar(initialAvatar);

    await tester.superPump(
        EditProfilePage.createForTesting(initialUserParams, initialAvatar));
    expect(find.text('Bob Kelso'), findsOneWidget);
    expect(find.text('Hello there!'), findsOneWidget);
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('without initial params', (WidgetTester tester) async {
    final initialUserParams = UserParams((e) => e
      ..name = null
      ..selfDescription = null
      ..avatarId = null);
    const Uri? initialAvatar = null;

    await userParamsController.setUserParams(initialUserParams);
    await userAvatarManager.deleteUserAvatar();

    await tester.superPump(
        EditProfilePage.createForTesting(initialUserParams, initialAvatar));
    expect(find.byType(UriImagePlante), findsNothing);
    // We mostly test that the widget does not crash
  });

  testWidgets('update user params', (WidgetTester tester) async {
    final initialParams = UserParams((e) => e
      ..name = 'Bob Kelso'
      ..selfDescription = 'Hello there!');
    await userParamsController.setUserParams(initialParams);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));

    await tester.superEnterText(
        find.byKey(const Key('name_input')), 'Perry Cox');
    await tester.superEnterText(find.byKey(const Key('self_description_input')),
        'Doctor, Doctor, give me a cure');

    expect(await userParamsController.getUserParams(), equals(initialParams));
    verifyNever(backend.updateUserParams(any));
    expect(find.byType(EditProfilePage), findsOneWidget);

    await tester.superTap(find.text(context.strings.global_save));

    final expectedParams = initialParams.rebuild((e) => e
      ..name = 'Perry Cox'
      ..selfDescription = 'Doctor, Doctor, give me a cure');
    // Local user params updated
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    // User params are sent to the backend
    verify(backend.updateUserParams(expectedParams));
    // User avatar IS NOT changed
    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(0));
    // The page is closed
    expect(find.byType(EditProfilePage), findsNothing);
  });

  testWidgets('update user avatar', (WidgetTester tester) async {
    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));

    // No avatar
    expect(find.byType(UriImagePlante), findsNothing);
    // Change avatar click
    await tester.superTap(find.byKey(const Key('change_avatar_button')));
    // Avatar selected
    expect(find.byType(UriImagePlante), findsOneWidget);

    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(0));
    expect(find.byType(EditProfilePage), findsOneWidget);

    await tester.superTap(find.text(context.strings.global_save));

    final expectedParams = initialParams.rebuild((e) => e.avatarId = avatarId);
    expect(expectedParams, isNot(equals(initialParams)));
    // Local user params are almost same
    expect(await userParamsController.getUserParams(), equals(expectedParams));
    // User params are NOT sent to the backend - user params were not changed
    verifyNever(backend.updateUserParams(any));
    // User avatar IS changed
    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(1));
    // The page is closed
    expect(find.byType(EditProfilePage), findsNothing);
  });

  testWidgets('no changes but Save pressed', (WidgetTester tester) async {
    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));
    await tester.superTap(find.text(context.strings.global_save));

    // Local user params are not changed
    expect(await userParamsController.getUserParams(), equals(initialParams));
    // User params are not sent to the backend
    verifyNever(backend.updateUserParams(any));
    // User avatar is not changed
    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(0));
    // The page is closed
    expect(find.byType(EditProfilePage), findsNothing);
  });

  testWidgets('back pressed without changes', (WidgetTester tester) async {
    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);

    await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));

    await tester.superTap(find.byKey(const Key('back_button')));

    // Local user params are not changed
    expect(await userParamsController.getUserParams(), equals(initialParams));
    // User params are not sent to the backend
    verifyNever(backend.updateUserParams(any));
    // User avatar is not changed
    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(0));
    // The page is closed
    expect(find.byType(EditProfilePage), findsNothing);
  });

  testWidgets('back pressed with user params changes',
      (WidgetTester tester) async {
    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));
    await tester.superEnterText(
        find.byKey(const Key('name_input')), 'Perry Cox');

    expect(find.text(context.strings.edit_profile_page_cancel_editing_q),
        findsNothing);
    await tester.superTap(find.byKey(const Key('back_button')));

    // Not closed yet
    expect(find.byType(EditProfilePage), findsOneWidget);
    // The user is asked if they really want to close the page
    expect(find.text(context.strings.edit_profile_page_cancel_editing_q),
        findsOneWidget);

    await tester.superTap(find.text(context.strings.global_yes));

    // The page is closed
    expect(find.byType(EditProfilePage), findsNothing);
    // Nothing is changed - the page is canceled
    expect(await userParamsController.getUserParams(), equals(initialParams));
    verifyNever(backend.updateUserParams(any));
    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(0));
  });

  testWidgets('back pressed with avatar changes', (WidgetTester tester) async {
    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));

    // Select an avatar
    expect(find.byType(UriImagePlante), findsNothing);
    await tester.superTap(find.byKey(const Key('change_avatar_button')));
    expect(find.byType(UriImagePlante), findsOneWidget);

    expect(find.text(context.strings.edit_profile_page_cancel_editing_q),
        findsNothing);
    await tester.superTap(find.byKey(const Key('back_button')));

    // Not closed yet
    expect(find.byType(EditProfilePage), findsOneWidget);
    // The user is asked if they really want to close the page
    expect(find.text(context.strings.edit_profile_page_cancel_editing_q),
        findsOneWidget);

    await tester.superTap(find.text(context.strings.global_yes));

    // The page is closed
    expect(find.byType(EditProfilePage), findsNothing);
    // Nothing is changed - the page is canceled
    expect(await userParamsController.getUserParams(), equals(initialParams));
    verifyNever(backend.updateUserParams(any));
    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(0));
  });

  testWidgets('back pressed with changes, but closing is canceled',
      (WidgetTester tester) async {
    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));
    await tester.superEnterText(
        find.byKey(const Key('name_input')), 'Perry Cox');

    expect(find.text(context.strings.edit_profile_page_cancel_editing_q),
        findsNothing);
    await tester.superTap(find.byKey(const Key('back_button')));

    // Not closed yet
    expect(find.byType(EditProfilePage), findsOneWidget);
    // The user is asked if they really want to close the page
    expect(find.text(context.strings.edit_profile_page_cancel_editing_q),
        findsOneWidget);

    await tester.superTap(find.text(context.strings.global_no));

    // The user is no longer asked
    expect(find.text(context.strings.edit_profile_page_cancel_editing_q),
        findsNothing);
    // The page is not closed
    expect(find.byType(EditProfilePage), findsOneWidget);

    // Nothing is changed - the page is still opened
    expect(await userParamsController.getUserParams(), equals(initialParams));
    verifyNever(backend.updateUserParams(any));
    expect(userAvatarManager.callsUpdateUserAvatar_callsCount(), equals(0));
  });

  testWidgets('error when saving user params', (WidgetTester tester) async {
    when(backend.updateUserParams(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));

    // Change name
    await tester.superEnterText(
        find.byKey(const Key('name_input')), 'Perry Cox');

    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
    await tester.superTap(find.text(context.strings.global_save));

    // Error shown
    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);
    // User params are not saved
    expect(await userParamsController.getUserParams(), equals(initialParams));
  });

  testWidgets('error when saving user avatar', (WidgetTester tester) async {
    // Avatar will be successfully selected
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);
    // But the backend operation will end up with an error
    userAvatarManager.setUpdateUserAvatarError_testing(BackendError.other());

    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);

    final context = await tester
        .superPump(EditProfilePage.createForTesting(initialParams, null));

    // Select an avatar
    expect(find.byType(UriImagePlante), findsNothing);
    await tester.superTap(find.byKey(const Key('change_avatar_button')));
    expect(find.byType(UriImagePlante), findsOneWidget);

    expect(
        find.text(context.strings.global_something_went_wrong), findsNothing);
    await tester.superTap(find.text(context.strings.global_save));

    // Error shown
    expect(
        find.text(context.strings.global_something_went_wrong), findsOneWidget);
  });

  testWidgets('lost photo is retrieved on start', (WidgetTester tester) async {
    expect(
        userAvatarManager.retrieveLostSelectedAvatar_callsCount(), equals(0));

    final initialParams = UserParams((e) => e.name = 'Bob Kelso');
    await userParamsController.setUserParams(initialParams);
    await tester.superPump(EditProfilePage.createForTesting(initialParams, null,
        key: const Key('widget1')));

    // We expect the widget to try to recover a lost avatar ...
    expect(
        userAvatarManager.retrieveLostSelectedAvatar_callsCount(), equals(1));

    // ... but the first widget is without a lost gallery avatar
    expect(find.byType(UriImagePlante), findsNothing);

    // Now let's put some lost avatar out there
    userAvatarManager.setLostSelectedGalleryImage_testing(imagePath);

    // And create a second widget
    await tester.superPump(EditProfilePage.createForTesting(initialParams, null,
        key: const Key('widget2')));

    // We expect the widget to try to recover a lost avatar again
    expect(
        userAvatarManager.retrieveLostSelectedAvatar_callsCount(), equals(2));

    // Second widget is expected to recover the lost avatar
    expect(find.byType(UriImagePlante), findsOneWidget);
  });
}
