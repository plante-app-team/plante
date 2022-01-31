import 'package:flutter/src/widgets/framework.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';

import 'fake_user_params_controller.dart';

class FakeUserAvatarManager implements UserAvatarManager {
  static const DEFAULT_AVATAR_ID = 'DEFAULT_AVATAR_ID';

  final FakeUserParamsController userParamsController;

  Uri? _selectedGalleryImage;
  Uri? _lostSelectedGalleryImage;
  Uri? _userAvatar;
  BackendError? _updateUserAvatarError;
  final _observers = <UserAvatarManagerObserver>[];

  var _callsCountSelectAvatar = 0;
  var _callsCountRetrieveLostAvatar = 0;
  var _callsUpdateUserAvatar = 0;

  FakeUserAvatarManager(this.userParamsController);

  // ignore: non_constant_identifier_names
  void setSelectedGalleryImage_testing(Uri? image) =>
      _selectedGalleryImage = image;

  // ignore: non_constant_identifier_names
  void setLostSelectedGalleryImage_testing(Uri? image) =>
      _lostSelectedGalleryImage = image;

  // ignore: non_constant_identifier_names
  void setUpdateUserAvatarError_testing(BackendError? error) =>
      _updateUserAvatarError = error;

  // ignore: non_constant_identifier_names
  int askUserToSelectImageFromGallery_callsCount() => _callsCountSelectAvatar;

  // ignore: non_constant_identifier_names
  int retrieveLostSelectedAvatar_callsCount() => _callsCountRetrieveLostAvatar;

  // ignore: non_constant_identifier_names
  int callsUpdateUserAvatar_callsCount() => _callsUpdateUserAvatar;

  @override
  void addObserver(UserAvatarManagerObserver observer) =>
      _observers.add(observer);

  @override
  void removeObserver(UserAvatarManagerObserver observer) =>
      _observers.remove(observer);

  @override
  Future<Uri?> retrieveLostSelectedAvatar(BuildContext context) async {
    _callsCountRetrieveLostAvatar += 1;
    return _lostSelectedGalleryImage;
  }

  @override
  Future<Uri?> askUserToSelectImageFromGallery(BuildContext context,
      {required bool iHaveTriedRetrievingLostImage}) async {
    _callsCountSelectAvatar += 1;
    return _selectedGalleryImage;
  }

  @override
  Future<Map<String, String>> userAvatarAuthHeaders() async => {'auth': 'cool'};

  @override
  Future<Result<String, BackendError>> updateUserAvatar(
      Uri avatarFilePath) async {
    _callsUpdateUserAvatar += 1;
    if (_updateUserAvatarError != null) {
      return Err(_updateUserAvatarError!);
    }
    _userAvatar = avatarFilePath;
    _observers.forEach((o) => o.onUserAvatarChange());
    await userParamsController.setUserParams(userParamsController
        .cachedUserParams
        ?.rebuild((e) => e.avatarId = DEFAULT_AVATAR_ID));
    return Ok(DEFAULT_AVATAR_ID);
  }

  @override
  Future<Uri?> userAvatarUri() async => _userAvatar;

  @override
  Future<Result<None, BackendError>> deleteUserAvatar() async {
    _userAvatar = null;
    _observers.forEach((o) => o.onUserAvatarChange());
    return Ok(None());
  }
}
