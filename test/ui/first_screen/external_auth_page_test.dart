import 'package:either_option/either_option.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/outside/identity/google_authorizer.dart';
import 'package:untitled_vegan_app/outside/identity/google_user.dart';
import 'package:untitled_vegan_app/model/user_params.dart';
import 'package:untitled_vegan_app/ui/first_screen/external_auth_page.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '../../widget_tester_extension.dart';
import 'external_auth_page_test.mocks.dart';

@GenerateMocks([GoogleAuthorizer, Backend])
void main() {
  setUp(() {
    GetIt.I.reset();
  });

  testWidgets("App name is concatenated with greeting", (WidgetTester tester) async {
    final context = await tester.superPump(ExternalAuthPage((unused) async { return true; }));
    final str = context.strings.external_auth_page_search_products_with + " " + context.strings.global_app_name;
    final titleFinder = find.text(str);
    expect(titleFinder, findsOneWidget);
  });

  testWidgets("Successful Google Sign in", (WidgetTester tester) async {
    final googleAuthorizer = MockGoogleAuthorizer();
    final backend = MockBackend();
    GetIt.I.registerSingleton<GoogleAuthorizer>(googleAuthorizer);
    GetIt.I.registerSingleton<Backend>(backend);

    final googleUser = GoogleUser("bob", "bob@bo.net", "123", DateTime.now());
    when(googleAuthorizer.auth()).thenAnswer((_) async => googleUser);
    when(backend.loginOrRegister(any)).thenAnswer((_) async => Left(UserParams()));

    UserParams? obtainedParams;
    final context = await tester.superPump(
        ExternalAuthPage((params) async {
          obtainedParams = params;
          return true;
        }));

    await tester.tap(find.text(context.strings.external_auth_page_continue_with_google));

    expect(obtainedParams, isNot(equals(null)));
  });

  testWidgets("Not successful Google Sign in", (WidgetTester tester) async {
    final mock = MockGoogleAuthorizer();
    GetIt.I.registerSingleton<GoogleAuthorizer>(mock);
    when(mock.auth()).thenAnswer((_) async => null);

    UserParams? obtainedResult;
    final context = await tester.superPump(
        ExternalAuthPage((params) async {
          obtainedResult = params;
          return true;
        }));

    await tester.tap(find.text(context.strings.external_auth_page_continue_with_google));

    expect(obtainedResult, equals(null));
  });
}
