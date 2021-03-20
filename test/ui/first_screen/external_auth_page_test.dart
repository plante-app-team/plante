import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:untitled_vegan_app/identity/google_authorizer.dart';
import 'package:untitled_vegan_app/identity/google_user.dart';
import 'package:untitled_vegan_app/ui/first_screen/external_auth_page.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';

import '../../widget_tester_extension.dart';
import 'external_auth_page_test.mocks.dart';

@GenerateMocks([GoogleAuthorizer])
void main() {
  setUp(() {
    GetIt.I.reset();
  });

  testWidgets("App name is concatenated with greeting", (WidgetTester tester) async {
    final context = await tester.superPump(ExternalAuthPage((unused){}));
    final str = context.strings.external_auth_page_search_products_with + " " + context.strings.global_app_name;
    final titleFinder = find.text(str);
    expect(titleFinder, findsOneWidget);
  });

  testWidgets("Successful Google Sign in", (WidgetTester tester) async {
    final mock = MockGoogleAuthorizer();
    GetIt.I.registerSingleton<GoogleAuthorizer>(mock);
    final googleUser = GoogleUser("bob", "bob@bo.net", "123", DateTime.now());
    when(mock.auth()).thenAnswer((_) async => googleUser);

    GoogleUser? obtainedParams;
    final context = await tester.superPump(
        ExternalAuthPage((params) { obtainedParams = params.googleUser; }));

    await tester.tap(find.text(context.strings.external_auth_page_continue_with_google));

    expect(obtainedParams, equals(googleUser));
  });

  testWidgets("Not successful Google Sign in", (WidgetTester tester) async {
    final mock = MockGoogleAuthorizer();
    GetIt.I.registerSingleton<GoogleAuthorizer>(mock);
    when(mock.auth()).thenAnswer((_) async => null);

    ExternalAuthResult? obtainedResult;
    final context = await tester.superPump(
        ExternalAuthPage((result) { obtainedResult = result; }));

    await tester.tap(find.text(context.strings.external_auth_page_continue_with_google));

    expect(obtainedResult, equals(null));
  });
}
