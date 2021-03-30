import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled_vegan_app/outside/identity/google_user.dart';

class GoogleAuthorizer {
  Future<GoogleUser?> auth() async {
    GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: "PLANTE_ANDROID_GOOGLE_CLOUD_CLIENT_ID");

    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        // TODO(https://trello.com/c/XWAE5UVB/): log warning
        return null;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        // TODO(https://trello.com/c/XWAE5UVB/): log warning
        return null;
      }

      return GoogleUser(
          account.displayName ?? "",
          account.email,
          idToken,
          DateTime.now().toUtc());
    } catch (error) {
      // TODO(https://trello.com/c/XWAE5UVB/): report an error
      print(error);
      return null;
    }
  }
}
