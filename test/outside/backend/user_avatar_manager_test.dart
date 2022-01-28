import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/photos/photo_requester.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_user_params_controller.dart';

void main() {
  final imagePath = Uri.file(File('./test/assets/img.jpg').absolute.path);
  final avatarUrl = Uri.parse('https://planteapp.com/avatar.jpg');
  const avatarId = 'avatarID';
  late MockBackend backend;
  late FakeUserParamsController userParamsController;
  late MockPhotosTaker photosTaker;

  late UserAvatarManager userAvatarManager;

  setUp(() {
    backend = MockBackend();
    userParamsController = FakeUserParamsController();
    photosTaker = MockPhotosTaker();
    userAvatarManager =
        UserAvatarManager(backend, userParamsController, photosTaker);

    userParamsController.setUserParams(UserParams((e) => e.name = 'Bob'));

    when(backend.updateUserAvatar(any)).thenAnswer((_) async => Ok(avatarId));
    when(backend.deleteUserAvatar()).thenAnswer((_) async => Ok(None()));
    when(backend.userAvatarUrl(any)).thenAnswer((_) => avatarUrl);
  });

  test('update avatar', () async {
    final observer = _UserAvatarManagerObserver();
    userAvatarManager.addObserver(observer);
    final avatarBytes = await File.fromUri(imagePath).readAsBytes();

    expect(observer.notificationsCount, equals(0));
    expect(userParamsController.cachedUserParams?.avatarId, isNull);
    verifyNever(backend.updateUserAvatar(any));

    final result = await userAvatarManager.updateUserAvatar(imagePath);
    expect(result.isOk, isTrue);

    expect(observer.notificationsCount, equals(1));
    expect(userParamsController.cachedUserParams?.avatarId, equals(avatarId));
    final capturedBytes = verify(backend.updateUserAvatar(captureAny))
        .captured
        .first as Uint8List;
    expect(capturedBytes, equals(avatarBytes));
  });

  test('update avatar failure', () async {
    when(backend.updateUserAvatar(any))
        .thenAnswer((_) async => Err(BackendError.other()));

    final observer = _UserAvatarManagerObserver();
    userAvatarManager.addObserver(observer);

    final result = await userAvatarManager.updateUserAvatar(imagePath);
    expect(result.isErr, isTrue);

    verify(backend.updateUserAvatar(any));
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
    verifyNever(backend.deleteUserAvatar());

    final result = await userAvatarManager.deleteUserAvatar();
    expect(result.isOk, isTrue);

    expect(observer.notificationsCount, equals(1));
    expect(userParamsController.cachedUserParams?.avatarId, isNull);
    verify(backend.deleteUserAvatar());
  });

  test('delete avatar failure', () async {
    when(backend.deleteUserAvatar())
        .thenAnswer((_) async => Err(BackendError.other()));

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
    final result = await userAvatarManager.userAvatarUri();
    verify(backend.userAvatarUrl(userParamsController.cachedUserParams));
    expect(result, equals(avatarUrl));
  });

  test('no user avatar url', () async {
    await userParamsController.setUserParams(null);
    final result = await userAvatarManager.userAvatarUri();
    expect(result, isNull);
  });

  test('user avatar headers', () async {
    const headers = {
      'header1': 'value1',
      'header2': 'value2',
    };
    when(backend.authHeaders()).thenAnswer((_) async => headers);

    final result = await userAvatarManager.userAvatarAuthHeaders();
    expect(result, headers);
  });

  test('select avatar', () async {
    when(photosTaker.selectAndCropPhoto(any, any, any,
            cropCircle: anyNamed('cropCircle'),
            targetSize: anyNamed('targetSize'),
            minSize: anyNamed('minSize')))
        .thenAnswer((_) async => imagePath);

    verifyNever(photosTaker.selectAndCropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
        minSize: anyNamed('minSize')));
    final result = await userAvatarManager.askUserToSelectImageFromGallery(
        _MockBuildContext(),
        iHaveTriedRetrievingLostImage: true);
    verify(photosTaker.selectAndCropPhoto(any, any, PhotoRequester.AVATAR_INIT,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
        minSize: anyNamed('minSize')));

    expect(result, equals(imagePath));
  });

  test('select avatar canceled by user', () async {
    when(photosTaker.selectAndCropPhoto(any, any, any,
            cropCircle: anyNamed('cropCircle'),
            targetSize: anyNamed('targetSize'),
            minSize: anyNamed('minSize')))
        .thenAnswer((_) async => null);

    verifyNever(photosTaker.selectAndCropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
        minSize: anyNamed('minSize')));
    final result = await userAvatarManager.askUserToSelectImageFromGallery(
        _MockBuildContext(),
        iHaveTriedRetrievingLostImage: true);
    verify(photosTaker.selectAndCropPhoto(any, any, PhotoRequester.AVATAR_INIT,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
        minSize: anyNamed('minSize')));

    expect(result, isNull);
  });

  test('retrieve lost selected avatar', () async {
    when(photosTaker.retrieveLostPhoto(any))
        .thenAnswer((_) async => Ok(imagePath));
    when(photosTaker.cropPhoto(any, any, any,
            cropCircle: anyNamed('cropCircle'),
            targetSize: anyNamed('targetSize'),
            minSize: anyNamed('minSize')))
        .thenAnswer((_) async => imagePath);

    verifyNever(photosTaker.retrieveLostPhoto(any));
    verifyNever(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
        minSize: anyNamed('minSize')));
    final result =
        await userAvatarManager.retrieveLostSelectedAvatar(_MockBuildContext());
    verify(photosTaker.retrieveLostPhoto(PhotoRequester.AVATAR_INIT));
    verify(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
        minSize: anyNamed('minSize')));

    expect(result, equals(imagePath));
  });

  test('retrieve lost selected avatar, no lost images', () async {
    when(photosTaker.retrieveLostPhoto(any)).thenAnswer((_) async => null);

    verifyNever(photosTaker.retrieveLostPhoto(any));
    verifyNever(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
        minSize: anyNamed('minSize')));
    final result =
        await userAvatarManager.retrieveLostSelectedAvatar(_MockBuildContext());
    verify(photosTaker.retrieveLostPhoto(PhotoRequester.AVATAR_INIT));
    verifyNever(photosTaker.cropPhoto(any, any, any,
        cropCircle: anyNamed('cropCircle'),
        targetSize: anyNamed('targetSize'),
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
