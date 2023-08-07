import 'package:mockito/mockito.dart';
import 'package:plante/outside/backend/cmds/user_avatar_cmds.dart';
import 'package:plante/outside/backend/user_params_auto_wiper.dart';
import 'package:test/test.dart';

import '../../common_mocks.mocks.dart';
import '../../z_fakes/fake_backend.dart';

void main() {
  test('Wipes user params on unauthorized server error', () async {
    final backend = FakeBackend();
    final userParametersController = MockUserParamsController();
    final _ = UserParamsAutoWiper(backend, userParametersController);

    verifyNever(userParametersController.setUserParams(any));

    // Some other error
    backend.setResponse_testing(DELETE_USER_AVATAR_CMD, '', responseCode: 500);
    await backend.deleteUserAvatar();
    verifyNever(userParametersController.setUserParams(any));

    // Not authorized error
    backend.setResponse_testing(DELETE_USER_AVATAR_CMD, '', responseCode: 401);
    await backend.deleteUserAvatar();
    verify(userParametersController.setUserParams(null));
  });
}
