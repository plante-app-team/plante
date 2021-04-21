import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_params_auto_wiper.dart';
import 'package:plante/model/user_params_controller.dart';

import 'user_params_auto_wiper_test.mocks.dart';

@GenerateMocks([UserParamsController, Backend])
void main() {
  test('Wipes user params on unauthorized server error', () async {
    final backend = MockBackend();
    BackendObserver? observer;
    when(backend.addObserver(any)).thenAnswer((realInvocation) {
      observer = realInvocation.positionalArguments[0];
    });
    final userParametersController = MockUserParamsController();
    final _ = UserParamsAutoWiper(backend, userParametersController);

    verifyNever(userParametersController.setUserParams(any));

    // Some other error
    observer!.onBackendError(BackendErrorKind.OTHER.toErrorForTesting());
    verifyNever(userParametersController.setUserParams(any));

    // Not authorized error
    observer!.onBackendError(BackendErrorKind.NOT_AUTHORIZED.toErrorForTesting());
    verify(userParametersController.setUserParams(null));
  });
}
