import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/profile/edit_user_data_widget.dart';

import '../../widget_tester_extension.dart';
import '../../z_fakes/fake_user_avatar_manager.dart';

void main() {
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
  late FakeUserAvatarManager userAvatarManager;

  setUp(() async {
    userAvatarManager = FakeUserAvatarManager();
  });

  testWidgets('no initial data', (WidgetTester tester) async {
    final emptyUserParams = () async => UserParams();
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: emptyUserParams.call());

    await tester.superPump(EditUserDataWidget(controller: controller));

    final nameWidget = find.byKey(const Key('name')).evaluate().first.widget
        as InputFieldPlante;
    expect(nameWidget.controller!.text, isEmpty);
    expect(find.byType(UriImagePlante), findsNothing);
  });

  testWidgets('with initial data', (WidgetTester tester) async {
    userAvatarManager.setUserAvatar_testing(imagePath);
    final userParams = () async => UserParams((e) => e.name = 'Bob');
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: userParams.call());

    await tester.superPump(EditUserDataWidget(controller: controller));

    final nameWidget = find.byKey(const Key('name')).evaluate().first.widget
        as InputFieldPlante;
    expect(nameWidget.controller!.text, equals('Bob'));
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('short user name is not valid user data',
      (WidgetTester tester) async {
    userAvatarManager.setUserAvatar_testing(imagePath);
    final userParams = () async => UserParams((e) => e.name = 'Bob Kelso');
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: userParams.call());
    await tester.superPump(EditUserDataWidget(controller: controller));

    // Long name
    expect(controller.isDataValid(), isTrue);

    // Short name
    await tester.superEnterText(find.byKey(const Key('name')),
        'a' * (EditUserDataWidget.MIN_NAME_LENGTH - 1));
    expect(controller.isDataValid(), isFalse);

    // Long name again
    await tester.superEnterText(find.byKey(const Key('name')),
        'a' * (EditUserDataWidget.MIN_NAME_LENGTH));
    expect(controller.isDataValid(), isTrue);
  });

  testWidgets('controller can change user name in widget',
      (WidgetTester tester) async {
    userAvatarManager.setUserAvatar_testing(imagePath);
    final emptyUserParams = () async => UserParams();
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: emptyUserParams.call());
    await tester.superPump(EditUserDataWidget(controller: controller));

    var nameWidget = find.byKey(const Key('name')).evaluate().first.widget
        as InputFieldPlante;
    expect(nameWidget.controller!.text, isEmpty);

    controller.userParams =
        controller.userParams.rebuild((e) => e.name = 'Bob');
    await tester.pumpAndSettle();

    nameWidget = find.byKey(const Key('name')).evaluate().first.widget
        as InputFieldPlante;
    expect(nameWidget.controller!.text, equals('Bob'));
  });

  testWidgets('controller can change user avatar in widget',
      (WidgetTester tester) async {
    userAvatarManager.setUserAvatar_testing(null);
    final emptyUserParams = () async => UserParams();
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: emptyUserParams.call());
    await tester.superPump(EditUserDataWidget(controller: controller));

    expect(find.byType(UriImagePlante), findsNothing);
    expect(controller.userParams.hasAvatar, isFalse);

    controller.userAvatar = imagePath;
    await tester.pumpAndSettle();

    expect(find.byType(UriImagePlante), findsOneWidget);
    expect(controller.userParams.hasAvatar, isTrue);
  });

  testWidgets('user name in widget changes', (WidgetTester tester) async {
    final emptyUserParams = () async => UserParams((e) => e.name = '');
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: emptyUserParams.call());
    await tester.superPump(EditUserDataWidget(controller: controller));

    var notificationsCount = 0;
    controller.registerChangeCallback(() => notificationsCount += 1);

    expect(notificationsCount, equals(0));
    expect(controller.userParams.name, isEmpty);

    await tester.superEnterText(find.byKey(const Key('name')), 'B');

    // Callback is notified
    expect(notificationsCount, equals(1));
    // Controller gets the change
    expect(controller.userParams.name, equals('B'));
  });

  testWidgets('user avatar in widget changes', (WidgetTester tester) async {
    userAvatarManager.setSelectedGalleryImage_testing(imagePath);

    final emptyUserParams = () async => UserParams((e) => e.name = '');
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: emptyUserParams.call());
    await tester.superPump(EditUserDataWidget(controller: controller));

    var notificationsCount = 0;
    controller.registerChangeCallback(() => notificationsCount += 1);

    expect(notificationsCount, equals(0));
    expect(controller.userParams.hasAvatar, isFalse);
    expect(controller.userAvatar, isNull);

    await tester.superTap(find.byKey(const Key('change_avatar_button')));

    // Callback is notified
    expect(notificationsCount, equals(1));
    // Avatar is set
    expect(controller.userParams.hasAvatar, isTrue);
    expect(controller.userAvatar, equals(imagePath));
  });

  testWidgets('lost photo is retrieved on start', (WidgetTester tester) async {
    expect(
        userAvatarManager.retrieveLostSelectedAvatar_callsCount(), equals(0));

    final emptyUserParams = () async => UserParams((e) => e.name = '');
    var controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: emptyUserParams.call());
    await tester.superPump(
        EditUserDataWidget(key: const Key('widget1'), controller: controller));

    // We expect the widget to try to recover a lost avatar ...
    expect(
        userAvatarManager.retrieveLostSelectedAvatar_callsCount(), equals(1));

    // ... but the first widget is without a lost gallery avatar
    expect(controller.userParams.hasAvatar, isFalse);
    expect(controller.userAvatar, isNull);

    // Now let's put some lost avatar out there
    userAvatarManager.setLostSelectedGalleryImage_testing(imagePath);

    // And create a second widget, ...
    controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: emptyUserParams.call());
    await tester.superPump(
        EditUserDataWidget(key: const Key('widget2'), controller: controller));
    // Which we expect to recover the lost avatar
    expect(controller.userParams.hasAvatar, isTrue);
    expect(controller.userAvatar, equals(imagePath));
  });

  testWidgets('user avatar deletion', (WidgetTester tester) async {
    userAvatarManager.setUserAvatar_testing(imagePath);
    final userParams = () async => UserParams((e) => e
      ..name = ''
      ..hasAvatar = true);
    final controller = EditUserDataWidgetController(
        userAvatarManager: userAvatarManager,
        initialUserParams: userParams.call());
    final context =
        await tester.superPump(EditUserDataWidget(controller: controller));

    var notificationsCount = 0;
    controller.registerChangeCallback(() => notificationsCount += 1);

    expect(notificationsCount, equals(0));
    expect(controller.userParams.hasAvatar, isTrue);
    expect(controller.userAvatar, imagePath);
    expect(find.text(context.strings.edit_user_data_widget_avatar_delete),
        findsOneWidget);
    expect(find.text(context.strings.edit_user_data_widget_avatar_description),
        findsNothing);
    expect(find.byType(UriImagePlante), findsOneWidget);

    await tester.superTap(
        find.text(context.strings.edit_user_data_widget_avatar_delete));

    // Callback is notified
    expect(notificationsCount, equals(1));
    // Avatar is deleted
    expect(controller.userParams.hasAvatar, isFalse);
    expect(controller.userAvatar, isNull);
    // UI has changed
    expect(find.text(context.strings.edit_user_data_widget_avatar_delete),
        findsNothing);
    expect(find.text(context.strings.edit_user_data_widget_avatar_description),
        findsOneWidget);
    expect(find.byType(UriImagePlante), findsNothing);
  });
}
