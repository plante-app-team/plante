import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/identity/google_user.dart';

class GoogleAuthorizer {
  Future<GoogleUser?> auth() async {
    final String? clientId;
    if (Platform.isIOS) {
      clientId = dotenv.env['PLANTE_IOS_GOOGLE_CLOUD_CLIENT_ID_REVERSE'];
    } else {
      clientId = dotenv.env['PLANTE_ANDROID_GOOGLE_CLOUD_CLIENT_ID'];
    }
    final GoogleSignIn googleSignIn =
        GoogleSignIn(scopes: ['email', 'profile'], clientId: clientId);

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
