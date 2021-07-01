import 'package:plante/logging/log.dart';
import 'package:plante/outside/identity/apple_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthorizer {
  Future<AppleUser?> auth() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      return AppleUser(credential.givenName, credential.email,
          credential.authorizationCode, DateTime.now().toUtc());
    } catch (e) {
      Log.w('AppleAuthorizer: exception occurred', ex: e);
      return null;
    }
  }
}
