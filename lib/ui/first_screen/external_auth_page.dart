import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/identity/apple_authorizer.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/first_screen/init_user_page.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalAuthCallback = Future<bool> Function(UserParams userParams);

class ExternalAuthPage extends StatefulWidget {
  final ExternalAuthCallback _callback;

  const ExternalAuthPage(this._callback, {Key? key}) : super(key: key);

  @override
  _ExternalAuthPageState createState() => _ExternalAuthPageState(_callback);
}

class _ExternalAuthPageState extends PageStatePlante<ExternalAuthPage> {
  final GoogleAuthorizer _googleAuthorizer;
  final AppleAuthorizer _appleAuthorizer;
  bool _loading = false;
  final ExternalAuthCallback _callback;

  _ExternalAuthPageState(this._callback)
      : _googleAuthorizer = GetIt.I.get<GoogleAuthorizer>(),
        _appleAuthorizer = GetIt.I.get<AppleAuthorizer>(),
        super('ExternalAuthPage');

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Expanded(
        child: Stack(children: [
          Center(
              child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, bottom: 132),
                      child: Text(
                          context.strings.external_auth_page_continue_with,
                          style: TextStyles.headline1)))),
          Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (Platform.isAndroid || isInTests())
              Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24),
                  child: ButtonOutlinedPlante(
                      onPressed: !_loading ? _onGoogleAuthClicked : null,
                      child: Stack(children: [
                        Container(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: SvgPicture.asset(
                                          'assets/google_icon.svg')),
                                ])),
                        const SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                                child: Text('Google',
                                    style: TextStyles.buttonOutlinedEnabled)))
                      ]))),
            if (Platform.isIOS || isInTests())
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: SignInWithAppleButton(
                  text: context.strings.external_auth_page_continue_with_apple,
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  onPressed: !_loading ? _signInWithApple : () {},
                ),
              ),
          ])),
          Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 108),
                  child: InkWell(
                    onTap: () {
                      launch(PRIVACY_POLICY_URL);
                    },
                    child: Text(
                        context.strings.external_auth_page_privacy_policy,
                        style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline)),
                  ))),
          AnimatedSwitcher(
              duration: DURATION_DEFAULT,
              child: _loading
                  ? const LinearProgressIndicator()
                  : const SizedBox.shrink()),
          const InkWell(
              onTap: Log.startLogsSending,
              child: SizedBox(width: 50, height: 50)),
        ]),
      )
    ])));
  }

  void _signInWithApple() async {
    try {
      setState(() {
        _loading = true;
      });
      analytics.sendEvent('apple_auth_start');

      // Apple login
      final appleUser = await _appleAuthorizer.auth();
      if (appleUser == null) {
        analytics.sendEvent('apple_auth_apple_error');
        Log.w('ExternalAuthPage: Apple auth error');
        showSnackBar(context.strings.global_something_went_wrong, context);
        return;
      }

      // Universal auth logic
      final userParams = await _authUniversal(appleUser.name ?? '',
          appleAuthorizationCode: appleUser.authorizationCode);
      if (userParams == null) {
        return;
      }

      // Nice!
      await _callback.call(userParams);
      analytics.sendEvent('apple_auth_success');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onGoogleAuthClicked() async {
    try {
      setState(() {
        _loading = true;
      });
      analytics.sendEvent('google_auth_start');

      // Google login
      final googleAccount = await _googleAuthorizer.auth();
      if (googleAccount == null) {
        analytics.sendEvent('google_auth_google_error');
        Log.w('ExternalAuthPage: googleAccount == null');
        showSnackBar(context.strings.global_something_went_wrong, context);
        return;
      }

      // Universal auth logic
      final userParams = await _authUniversal(googleAccount.name,
          googleIdToken: googleAccount.idToken);
      if (userParams == null) {
        return;
      }

      // Nice!
      await _callback.call(userParams);
      analytics.sendEvent('google_auth_success');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<UserParams?> _authUniversal(String userName,
      {String? googleIdToken, String? appleAuthorizationCode}) async {
    // Backend login
    final backend = GetIt.I.get<Backend>();
    final loginResult = await backend.loginOrRegister(
        googleIdToken: googleIdToken,
        appleAuthorizationCode: appleAuthorizationCode);
    if (loginResult.isErr) {
      analytics.sendEvent('auth_backend_error');
      final error = loginResult.unwrapErr();
      if (error.errorKind == BackendErrorKind.GOOGLE_EMAIL_NOT_VERIFIED) {
        showSnackBar(
            context.strings.external_auth_page_google_email_not_verified,
            context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
      return null;
    }

    // Take external name
    var userParams = loginResult.unwrap();
    if ((userParams.name ?? '').length < InitUserPage.MIN_NAME_LENGTH) {
      userParams = userParams.rebuild((e) => e.name = userName);
    }
    return userParams;
  }
}
