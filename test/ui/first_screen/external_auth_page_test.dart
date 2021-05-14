import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/outside/identity/google_user.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/first_screen/external_auth_page.dart';

import '../../widget_tester_extension.dart';
import 'external_auth_page_test.mocks.dart';

@GenerateMocks([GoogleAuthorizer, Backend])
void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  testWidgets('Successful Google Sign in', (WidgetTester tester) async {
    final googleAuthorizer = MockGoogleAuthorizer();
    final backend = MockBackend();
    GetIt.I.registerSingleton<GoogleAuthorizer>(googleAuthorizer);
    GetIt.I.registerSingleton<Backend>(backend);

    final googleUser = GoogleUser('bob', 'bob@bo.net', '123', DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    when(backend.loginOrRegister(any)).thenAnswer((_) async => Ok(UserParams()));

    UserParams? obtainedParams;
    await tester.superPump(
        ExternalAuthPage((params) async {
          obtainedParams = params;
          return true;
        }));

    await tester.tap(find.text('Google'));

    expect(obtainedParams, isNot(equals(null)));
  });

  testWidgets('Not successful Google Sign in', (WidgetTester tester) async {
    final mock = MockGoogleAuthorizer();
    GetIt.I.registerSingleton<GoogleAuthorizer>(mock);
    when(mock.auth()).thenAnswer((_) async => null);

    UserParams? obtainedResult;
    await tester.superPump(
        ExternalAuthPage((params) async {
          obtainedResult = params;
          return true;
        }));

    await tester.tap(find.text('Google'));

    expect(obtainedResult, equals(null));
  });
}
