import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/input_field_multiline_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/profile/components/edit_user_data_widget.dart';

import '../../../widget_tester_extension.dart';

void main() {
  final userAvatarHeaders = () async {
    return const {'auth': 'cool'};
  };
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);

  InputFieldPlante nameWidget() {
    return find.byKey(const Key('name_input')).evaluate().first.widget
        as InputFieldPlante;
  }

  InputFieldMultilinePlante selfDescriptionWidget() {
    return find
        .byKey(const Key('self_description_input'))
        .evaluate()
        .first
        .widget as InputFieldMultilinePlante;
  }

  testWidgets('no initial data', (WidgetTester tester) async {
    final emptyUserParams = () async => UserParams();
    final emptyAvatar = () async => null;
    final controller = EditUserDataWidgetController(
        initialAvatar: emptyAvatar.call(),
        initialUserParams: emptyUserParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);

    await tester.superPump(EditUserDataWidget(controller: controller));

    expect(nameWidget().controller!.text, isEmpty);
    expect(selfDescriptionWidget().controller!.text, isEmpty);
    expect(find.byType(UriImagePlante), findsNothing);
  });

  testWidgets('with initial data', (WidgetTester tester) async {
    final userParams = () async => UserParams((e) => e
      ..name = 'Bob'
      ..selfDescription = 'Hello there');
    final avatar = () async => imagePath;
    final controller = EditUserDataWidgetController(
        initialAvatar: avatar.call(),
        initialUserParams: userParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);

    await tester.superPump(EditUserDataWidget(controller: controller));

    expect(nameWidget().controller!.text, equals('Bob'));
    expect(selfDescriptionWidget().controller!.text, equals('Hello there'));
    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('short user name is not valid user data',
      (WidgetTester tester) async {
    final userParams = () async => UserParams((e) => e.name = 'Bob Kelso');
    final avatar = () async => imagePath;
    final controller = EditUserDataWidgetController(
        initialAvatar: avatar.call(),
        initialUserParams: userParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    await tester.superPump(EditUserDataWidget(controller: controller));

    // Long name
    expect(controller.isDataValid(), isTrue);

    // Short name
    await tester.superEnterText(find.byKey(const Key('name_input')),
        'a' * (EditUserDataWidget.MIN_NAME_LENGTH - 1));
    expect(controller.isDataValid(), isFalse);

    // Long name again
    await tester.superEnterText(find.byKey(const Key('name_input')),
        'a' * (EditUserDataWidget.MIN_NAME_LENGTH));
    expect(controller.isDataValid(), isTrue);
  });

  testWidgets('long user name is shortened', (WidgetTester tester) async {
    final userParams = () async => UserParams((e) => e.name = 'Bob Kelso');
    final avatar = () async => imagePath;
    final controller = EditUserDataWidgetController(
        initialAvatar: avatar.call(),
        initialUserParams: userParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    await tester.superPump(EditUserDataWidget(controller: controller));

    // Not too long name
    expect(controller.isDataValid(), isTrue);

    // Too long name
    await tester.superEnterText(find.byKey(const Key('name_input')),
        'a' * (EditUserDataWidget.MAX_NAME_LENGTH * 2));

    // Data is still valid
    expect(controller.isDataValid(), isTrue);
    // The extra part is cut off
    expect(nameWidget().controller!.text,
        equals('a' * EditUserDataWidget.MAX_NAME_LENGTH));
  });

  testWidgets('controller can change user name in widget',
      (WidgetTester tester) async {
    final emptyUserParams = () async => UserParams();
    final emptyAvatar = () async => null;
    final controller = EditUserDataWidgetController(
        initialAvatar: emptyAvatar.call(),
        initialUserParams: emptyUserParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    await tester.superPump(EditUserDataWidget(controller: controller));

    expect(nameWidget().controller!.text, isEmpty);

    controller.userParams =
        controller.userParams.rebuild((e) => e.name = 'Bob');
    await tester.pumpAndSettle();

    expect(nameWidget().controller!.text, equals('Bob'));
  });

  testWidgets('controller can change user self description in widget',
      (WidgetTester tester) async {
    final emptyUserParams = () async => UserParams();
    final emptyAvatar = () async => null;
    final controller = EditUserDataWidgetController(
        initialAvatar: emptyAvatar.call(),
        initialUserParams: emptyUserParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    await tester.superPump(EditUserDataWidget(controller: controller));

    expect(selfDescriptionWidget().controller!.text, isEmpty);

    controller.userParams =
        controller.userParams.rebuild((e) => e.selfDescription = 'Hello there');
    await tester.pumpAndSettle();

    expect(selfDescriptionWidget().controller!.text, equals('Hello there'));
  });

  testWidgets('controller can change user avatar in widget',
      (WidgetTester tester) async {
    final emptyAvatar = () async => null;
    final emptyUserParams = () async => UserParams();
    final controller = EditUserDataWidgetController(
        initialAvatar: emptyAvatar.call(),
        initialUserParams: emptyUserParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    await tester.superPump(EditUserDataWidget(controller: controller));

    expect(find.byType(UriImagePlante), findsNothing);

    controller.userAvatar = imagePath;
    await tester.pumpAndSettle();

    expect(find.byType(UriImagePlante), findsOneWidget);
  });

  testWidgets('user name in widget changes', (WidgetTester tester) async {
    final emptyUserParams = () async => UserParams((e) => e.name = '');
    final emptyAvatar = () async => null;
    final controller = EditUserDataWidgetController(
        initialAvatar: emptyAvatar.call(),
        initialUserParams: emptyUserParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    await tester.superPump(EditUserDataWidget(controller: controller));

    var notificationsCount = 0;
    controller.registerChangeCallback(() => notificationsCount += 1);

    expect(notificationsCount, equals(0));
    expect(controller.userParams.name, isEmpty);

    await tester.superEnterText(find.byKey(const Key('name_input')), 'B');

    // Callback is notified
    expect(notificationsCount, equals(1));
    // Controller gets the change
    expect(controller.userParams.name, equals('B'));
  });

  testWidgets('user self description in widget changes',
      (WidgetTester tester) async {
    final emptyUserParams =
        () async => UserParams((e) => e.selfDescription = '');
    final emptyAvatar = () async => null;
    final controller = EditUserDataWidgetController(
        initialAvatar: emptyAvatar.call(),
        initialUserParams: emptyUserParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    await tester.superPump(EditUserDataWidget(controller: controller));

    var notificationsCount = 0;
    controller.registerChangeCallback(() => notificationsCount += 1);

    expect(notificationsCount, equals(0));
    expect(controller.userParams.selfDescription, isEmpty);

    await tester.superEnterText(
        find.byKey(const Key('self_description_input')), 'B');

    // Callback is notified
    expect(notificationsCount, equals(1));
    // Controller gets the change
    expect(controller.userParams.selfDescription, equals('B'));
  });

  testWidgets('user avatar in widget changes', (WidgetTester tester) async {
    final emptyUserParams = () async => UserParams((e) => e.name = '');
    final emptyAvatar = () async => null;
    final selectImageFromGallery = () async => imagePath;
    final controller = EditUserDataWidgetController(
        initialAvatar: emptyAvatar.call(),
        initialUserParams: emptyUserParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: selectImageFromGallery);
    await tester.superPump(EditUserDataWidget(controller: controller));

    var notificationsCount = 0;
    controller.registerChangeCallback(() => notificationsCount += 1);

    expect(notificationsCount, equals(0));
    expect(controller.userAvatar, isNull);

    await tester.superTap(find.byKey(const Key('change_avatar_button')));

    // Callback is notified
    expect(notificationsCount, equals(1));
    // Avatar is set
    expect(controller.userAvatar, equals(imagePath));
  });

  testWidgets('user avatar deletion', (WidgetTester tester) async {
    final userParams = () async => UserParams((e) => e
      ..name = ''
      ..avatarId = 'avatarID');
    final avatar = () async => imagePath;
    final controller = EditUserDataWidgetController(
        initialAvatar: avatar.call(),
        initialUserParams: userParams.call(),
        userAvatarHttpHeaders: userAvatarHeaders.call(),
        selectImageFromGallery: () async => null);
    final context =
        await tester.superPump(EditUserDataWidget(controller: controller));

    var notificationsCount = 0;
    controller.registerChangeCallback(() => notificationsCount += 1);

    expect(notificationsCount, equals(0));
    expect(controller.userParams.avatarId, equals('avatarID'));
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
    // Avatar is deleted ...
    expect(controller.userAvatar, isNull);
    // ... BUT avatar ID is not touched - it's up for the backend
    // to change the avatar ID.
    expect(controller.userParams.avatarId, equals('avatarID'));
    // UI has changed
    expect(find.text(context.strings.edit_user_data_widget_avatar_delete),
        findsNothing);
    expect(find.text(context.strings.edit_user_data_widget_avatar_description),
        findsOneWidget);
    expect(find.byType(UriImagePlante), findsNothing);
  });
}
