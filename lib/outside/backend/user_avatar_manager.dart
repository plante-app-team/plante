import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/result.dart';
import 'package:plante/base/size_int.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/ui/base/components/uri_image_plante.dart';
import 'package:plante/ui/photos/photo_requester.dart';
import 'package:plante/ui/photos/photos_taker.dart';

abstract class UserAvatarManagerObserver {
  void onUserAvatarChange();
}

class UserAvatarManager {
  static const _AVATAR_DIR = 'avatar_selection_dir';
  static const _AVATAR_SIZE = SizeInt(
    width: 460,
    height: 460,
  );
  static const _AVATAR_SIZE_MIN = SizeInt(
    width: 256,
    height: 256,
  );
  final _observers = <UserAvatarManagerObserver>[];
  final Backend _backend;
  final UserParamsController _userParamsController;
  final PhotosTaker _photosTaker;

  UserAvatarManager(
      this._backend, this._userParamsController, this._photosTaker);

  /// Returns user avatar ID on success.
  /// NOTE that the user avatar is also inserted into current user params by
  /// a call to UserParamsController - you should use the returned
  /// avatar ID only if there's no way to use UserParamsController.
  Future<Result<String, BackendError>> updateUserAvatar(
      Uri avatarFilePath) async {
    final Uint8List avatarBytes;
    try {
      avatarBytes = await File.fromUri(avatarFilePath).readAsBytes();
    } catch (e) {
      Log.e('Could not read user avatar file', ex: e);
      return Err(BackendError.other());
    }
    Log.i(
        'Uploading user avatar. Size: ${avatarBytes.length}, path: $avatarFilePath');
    final result = await _backend.updateUserAvatar(avatarBytes);
    if (result.isOk) {
      final avatarId = result.unwrap();
      final existingParams = await _userParamsController.getUserParams();
      if (existingParams != null) {
        await _userParamsController.setUserParams(
            existingParams.rebuild((params) => params.avatarId = avatarId));
      }
      _observers.forEach((observer) => observer.onUserAvatarChange());
    }
    return result;
  }

  Future<Result<None, BackendError>> deleteUserAvatar() async {
    Log.i('Deleting user avatar');
    final result = await _backend.deleteUserAvatar();
    if (result.isOk) {
      final existingParams = await _userParamsController.getUserParams();
      if (existingParams != null && existingParams.avatarId != null) {
        await _userParamsController.setUserParams(
            existingParams.rebuild((params) => params.avatarId = null));
      }
      _observers.forEach((observer) => observer.onUserAvatarChange());
    }
    return result;
  }

  /// NOTE: the URI is most likely URL, but it's not guaranteed to not change
  /// in the future.
  /// Please use the [UriImagePlante] class to show the image to avoid
  /// errors if paths to local files will be returned from the function in
  /// the future.
  Future<Uri?> userAvatarUri() async {
    final userParams = await _userParamsController.getUserParams();
    if (userParams == null) {
      return null;
    }
    return _backend.userAvatarUrl(userParams);
  }

  Future<Map<String, String>> userAvatarAuthHeaders() async {
    return _backend.authHeaders();
  }

  /// [iHaveTriedRetrievingLostImage] is required so that the programmer
  /// would be reminded of the necessity to call [retrieveLostSelectedAvatar].
  Future<Uri?> askUserToSelectImageFromGallery(BuildContext context,
      {required bool iHaveTriedRetrievingLostImage}) async {
    if (iHaveTriedRetrievingLostImage == false) {
      throw Exception('bruh');
    }
    return await _photosTaker.selectAndCropPhoto(
        context, await _avatarDir(), PhotoRequester.AVATAR_INIT,
        cropCircle: true, targetSize: _AVATAR_SIZE, minSize: _AVATAR_SIZE_MIN);
  }

  Future<Directory> _avatarDir() async {
    final tempDir = await getAppTempDir();
    final dir = Directory('${tempDir.path}/$_AVATAR_DIR');
    if (await dir.exists() == false) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Uri?> retrieveLostSelectedAvatar(BuildContext context) async {
    final lostPhotoRes =
        await _photosTaker.retrieveLostPhoto(PhotoRequester.AVATAR_INIT);
    if (lostPhotoRes == null) {
      return null;
    }
    if (lostPhotoRes.isErr) {
      Log.w('PhotosTaker error', ex: lostPhotoRes.unwrapErr());
      return null;
    }

    final lostPhoto = lostPhotoRes.unwrap();
    return await _photosTaker.cropPhoto(
        lostPhoto.path, context, await _avatarDir(),
        cropCircle: true, targetSize: _AVATAR_SIZE, minSize: _AVATAR_SIZE_MIN);
  }

  void addObserver(UserAvatarManagerObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(UserAvatarManagerObserver observer) {
    _observers.remove(observer);
  }
}
