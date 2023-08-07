import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/cmds/user_avatar_cmds.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/photos/photo_requester.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
  const avatarId = 'avatarID';
  late FakeBackend backend;
  late FakeUserParamsController userParamsController;
  late MockPhotosTaker photosTaker;

  late UserAvatarManager userAvatarManager;

  setUp(() {
    backend = FakeBackend();
    userParamsController = FakeUserParamsController();
    photosTaker = MockPhotosTaker();
    userAvatarManager =
        UserAvatarManager(backend, userParamsController, photosTaker);

    userParamsController.setUserParams(UserParams((e) => e.name = 'Bob'));

    backend.setResponse_testing(
        UPDATE_USER_AVATAR_CMD, jsonEncode({'result': avatarId}));
    backend.setResponse_testing(DELETE_USER_AVATAR_CMD, '{}');
  });

  test('update avatar', () async {
    final observer = _UserAvatarManagerObserver();
    userAvatarManager.addObserver(observer);

    expect(observer.notificationsCount, equals(0));
    expect(userParamsController.cachedUserParams?.avatarId, isNull);
    expect(
        backend.getRequestsMatching_testing(UPDATE_USER_AVATAR_CMD), isEmpty);

    final result = await userAvatarManager.updateUserAvatar(imagePath);
    expect(result.isOk, isTrue);

    expect(observer.notificationsCount, equals(1));
    expect(userParamsController.cachedUserParams?.avatarId, equals(avatarId));
    expect(backend.getRequestsMatching_testing(UPDATE_USER_AVATAR_CMD),
        isNot(isEmpty));
  });

  test('update avatar failure', () async {
    backend.setResponse_testing(UPDATE_USER_AVATAR_CMD, '', responseCode: 500);

    final observer = _UserAvatarManagerObserver();
    userAvatarManager.addObserver(observer);

    final result = await userAvatarManager.updateUserAvatar(imagePath);
    expect(result.isErr, isTrue);

    expect(backend.getRequestsMatching_testing(UPDATE_USER_AVATAR_CMD),
        isNot(isEmpty));
    expect(observer.notificationsCount, equals(0));
    expect(userParamsController.cachedUserParams?.avatarId, isNull);
  });

  test('delete avatar', () async {
    final observer = _UserAvatarManagerObserver();
    userAvatarManager.addObserver(observer);

    await userParamsController.setUserParams(UserParams((e) => e
      ..avatarId = avatarId
      ..name = 'Bob'));

    expect(observer.notificationsCount, equals(0));
    expect(userParamsController.cachedUserParams?.avatarId, equals(avatarId));
    expect(
        backend.getRequestsMatching_testing(DELETE_USER_AVATAR_CMD), isEmpty);

    final result = await userAvatarManager.deleteUserAvatar();
    expect(result.isOk, isTrue);

    expect(observer.notificationsCount, equals(1));
    expect(userParamsController.cachedUserParams?.avatarId, isNull);
    expect(backend.getRequestsMatching_testing(DELETE_USER_AVATAR_CMD),
        isNot(isEmpty));
  });

  test('delete avatar failure', () async {
    backend.setResponse_testing(DELETE_USER_AVATAR_CMD, '{}',
        responseCode: 500);

    final observer = _UserAvatarManagerObserver();
    userAvatarManager.addObserver(observer);

    await userParamsController.setUserParams(UserParams((e) => e
      ..avatarId = avatarId
      ..name = 'Bob'));

    final result = await userAvatarManager.deleteUserAvatar();
    expect(result.isErr, isTrue);

    expect(observer.notificationsCount, equals(0));
    expect(userParamsController.cachedUserParams?.avatarId, equals(avatarId));
  });

  test('user avatar url', () async {
    final params =
        (await userParamsController.getUserParams())!.rebuild((e) => e
          ..backendId = 'id'
          ..avatarId = avatarId);
    await userParamsController.setUserParams(params);

    final result = await userAvatarManager.userAvatarUri();
    expect(result!.path,
        contains('user_avatar_data/${params.backendId}/${params.avatarId}'));
  });

  test('other user avatar url', () async {
    final result = userAvatarManager.otherUserAvatarUri('user_id', 'avatar_id');
    expect(result!.path, contains('user_avatar_data/user_id/avatar_id'));
  });

  test('no user avatar url', () async {
    await userParamsController.setUserParams(null);
    final result = await userAvatarManager.userAvatarUri();
    expect(result, isNull);
  });

  test('user avatar headers', () async {
    final result = await userAvatarManager.userAvatarAuthHeaders();
    expect(result, equals(await backend.authHeaders()));
  });

  test('select avatar', () async {
    when(photosTaker.selectAndCropPhoto(any, any, any,
            cropCircle: anyNamed('cropCircle'),
            downsizeTo: anyNamed('downsizeTo'),
            minSize: anyNamed('minSize')))
        .thenAnswer((_) async => imagePath);

    verifyNever(photosTaker.selectAndCropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));
    final result = await userAvatarManager.askUserToSelectImageFromGallery(
        _MockBuildContext(),
        iHaveTriedRetrievingLostImage: true);
    verify(photosTaker.selectAndCropPhoto(any, any, PhotoRequester.AVATAR_INIT,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));

    expect(result, equals(imagePath));
  });

  test('select avatar canceled by user', () async {
    when(photosTaker.selectAndCropPhoto(any, any, any,
            cropCircle: anyNamed('cropCircle'),
            downsizeTo: anyNamed('downsizeTo'),
            minSize: anyNamed('minSize')))
        .thenAnswer((_) async => null);

    verifyNever(photosTaker.selectAndCropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));
    final result = await userAvatarManager.askUserToSelectImageFromGallery(
        _MockBuildContext(),
        iHaveTriedRetrievingLostImage: true);
    verify(photosTaker.selectAndCropPhoto(any, any, PhotoRequester.AVATAR_INIT,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));

    expect(result, isNull);
  });

  test('retrieve lost selected avatar', () async {
    when(photosTaker.retrieveLostPhoto(any))
        .thenAnswer((_) async => Ok(imagePath));
    when(photosTaker.cropPhoto(any, any, any,
            cropCircle: anyNamed('cropCircle'),
            downsizeTo: anyNamed('downsizeTo'),
            minSize: anyNamed('minSize')))
        .thenAnswer((_) async => imagePath);

    verifyNever(photosTaker.retrieveLostPhoto(any));
    verifyNever(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));
    final result =
        await userAvatarManager.retrieveLostSelectedAvatar(_MockBuildContext());
    verify(photosTaker.retrieveLostPhoto(PhotoRequester.AVATAR_INIT));
    verify(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));

    expect(result, equals(imagePath));
  });

  test('retrieve lost selected avatar, no lost images', () async {
    when(photosTaker.retrieveLostPhoto(any)).thenAnswer((_) async => null);

    verifyNever(photosTaker.retrieveLostPhoto(any));
    verifyNever(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));
    final result =
        await userAvatarManager.retrieveLostSelectedAvatar(_MockBuildContext());
    verify(photosTaker.retrieveLostPhoto(PhotoRequester.AVATAR_INIT));
    verifyNever(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        downsizeTo: anyNamed('downsizeTo'),
        minSize: anyNamed('minSize')));

    expect(result, isNull);
  });
}

class _UserAvatarManagerObserver implements UserAvatarManagerObserver {
  var notificationsCount = 0;
  @override
  void onUserAvatarChange() {
    notificationsCount += 1;
  }
}

class _MockBuildContext extends Mock implements BuildContext {}
