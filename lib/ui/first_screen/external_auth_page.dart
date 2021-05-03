import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/identity/google_authorizer.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalAuthCallback = Future<bool> Function(UserParams userParams);

class ExternalAuthPage extends StatefulWidget {
  final ExternalAuthCallback _callback;

  ExternalAuthPage(this._callback);

  @override
  _ExternalAuthPageState createState() => _ExternalAuthPageState(_callback);
}

class _ExternalAuthPageState extends State<ExternalAuthPage> {
  bool _loading = false;
  final ExternalAuthCallback _callback;

  _ExternalAuthPageState(this._callback);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Expanded(
        child: Stack(children: [
          Center(
              child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                      padding:
                          EdgeInsets.only(left: 24, right: 24, bottom: 132),
                      child: Text(
                          context.strings.external_auth_page_continue_with,
                          style: TextStyles.headline1)))),
          Center(
              child: Padding(
                  padding: EdgeInsets.only(left: 24, right: 24),
                  child: ButtonOutlinedPlante(
                      child: Stack(children: [
                        Container(
                            padding: EdgeInsets.only(left: 8),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: SvgPicture.asset(
                                          "assets/google_icon.svg")),
                                ])),
                        SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                                child: Text("Google",
                                    style: GoogleFonts.exo2(
                                        color: ColorsPlante.primary,
                                        fontSize: 18))))
                      ]),
                      onPressed: !_loading ? _onGoogleAuthClicked : null))),
          Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding: EdgeInsets.only(bottom: 108),
                  child: InkWell(
                      child: Text(
                          context.strings.external_auth_page_privacy_policy,
                          style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline)),
                      onTap: () {
                        launch(PRIVACY_POLICY_URL);
                      }))),
          AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              child: _loading ? LinearProgressIndicator() : SizedBox.shrink()),
          InkWell(
              child: SizedBox(width: 50, height: 50),
              onTap: Log.startLogsSending)
        ]),
      )
    ])));
  }

  void _onGoogleAuthClicked() async {
    try {
      setState(() {
        _loading = true;
      });

      final googleAccount = await GetIt.I.get<GoogleAuthorizer>().auth();
      if (googleAccount == null) {
        Log.w("ExternalAuthPage: googleAccount == null");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.strings.global_something_went_wrong)));
        return;
      }

      final backend = GetIt.I.get<Backend>();
      final loginResult = await backend.loginOrRegister(googleAccount.idToken);
      if (loginResult.isErr) {
        final error = loginResult.unwrapErr();
        if (error.errorKind == BackendErrorKind.GOOGLE_EMAIL_NOT_VERIFIED) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context
                  .strings.external_auth_page_google_email_not_verified)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context.strings.global_something_went_wrong)));
        }
        return;
      }

      _callback.call(loginResult.unwrap());
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
