import 'dart:typed_data';

import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';

const UPDATE_USER_AVATAR_CMD = 'user_avatar_upload';
const DELETE_USER_AVATAR_CMD = 'user_avatar_delete';

extension BackendExt on Backend {
  /// Returns user avatar ID
  Future<Result<String, BackendError>> updateUserAvatar(
          Uint8List avatarBytes) =>
      executeCmd(_UpdateUserAvatarCmd(avatarBytes));

  Future<Result<None, BackendError>> deleteUserAvatar() =>
      executeCmd(_DeleteUserAvatarCmd());

  Uri userAvatarUrl(String userId, String avatarId) {
    return createUrl('user_avatar_data/$userId/$avatarId', const {});
  }
}

class _UpdateUserAvatarCmd extends BackendCmd<String> {
  final Uint8List avatarBytes;

  _UpdateUserAvatarCmd(this.avatarBytes);

  @override
  Future<Result<String, BackendError>> execute() async {
    final jsonRes = await backendPostJson('$UPDATE_USER_AVATAR_CMD/', null,
        bodyBytes: avatarBytes);

    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    if (!json.containsKey('result')) {
      Log.w('Invalid user_avatar_upload response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }
    return Ok(json['result']!.toString());
  }
}

class _DeleteUserAvatarCmd extends BackendCmd<None> {
  _DeleteUserAvatarCmd();

  @override
  Future<Result<None, BackendError>> execute() async {
    final response = await backendGet('$DELETE_USER_AVATAR_CMD/', const {});
    return noneOrErrorFrom(response);
  }
}
