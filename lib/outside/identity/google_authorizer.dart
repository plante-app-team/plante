import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:plante/base/log.dart';
import 'package:plante/outside/identity/google_user.dart';

const CLIENTID_IOS = 'PLANTE_IOS_GOOGLE_CLOUD_CLIENT_ID';
const CLIENTID_ANDROID = 'PLANTE_ANDROID_GOOGLE_CLOUD_CLIENT_ID';

class GoogleAuthorizer {
  Future<GoogleUser?> auth() async {
    final clientId = Platform.isIOS ? CLIENTID_IOS : CLIENTID_ANDROID;
    final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: clientId);

    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        Log.w('GoogleAuthorizer: googleSignIn.signIn returned null');
        return null;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        Log.w('GoogleAuthorizer: authentication.idToken returned null');
        return null;
      }

      return GoogleUser(account.displayName ?? '', account.email, idToken,
          DateTime.now().toUtc());
    } catch (error) {
      Log.e('GoogleAuthorizer: exception occurred', ex: error);
      return null;
    }
  }
}
