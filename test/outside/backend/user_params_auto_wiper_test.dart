import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_params_auto_wiper.dart';

import '../../common_mocks.mocks.dart';

void main() {
  test('Wipes user params on unauthorized server error', () async {
    final backend = MockBackend();
    BackendObserver? observer;
    when(backend.addObserver(any)).thenAnswer((realInvocation) {
      observer = realInvocation.positionalArguments[0] as BackendObserver?;
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
