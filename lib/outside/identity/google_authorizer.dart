import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled_vegan_app/base/log.dart';
import 'package:untitled_vegan_app/outside/identity/google_user.dart';

class GoogleAuthorizer {
  Future<GoogleUser?> auth() async {
    GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: "PLANTE_ANDROID_GOOGLE_CLOUD_CLIENT_ID");

    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        Log.w("GoogleAuthorizer: googleSignIn.signIn returned null");
        return null;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        Log.w("GoogleAuthorizer: authentication.idToken returned null");
        return null;
      }

      return GoogleUser(
          account.displayName ?? "",
          account.email,
          idToken,
          DateTime.now().toUtc());
    } catch (error) {
      Log.e("GoogleAuthorizer: exception occurred", ex: error);
      return null;
    }
  }
}
