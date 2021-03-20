import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/identity/google_authorizer.dart';
import 'package:untitled_vegan_app/identity/google_user.dart';

class ExternalAuthResult {
  final GoogleUser? googleUser;
  ExternalAuthResult({this.googleUser});
}
typedef ExternalAuthCallback = void Function(ExternalAuthResult userParams);


class ExternalAuthPage extends StatefulWidget {
  final ExternalAuthCallback _callback;

  ExternalAuthPage(this._callback);

  @override
  _ExternalAuthPageState createState() => _ExternalAuthPageState(_callback);
}

class _ExternalAuthPageState extends State<ExternalAuthPage> {
  final ExternalAuthCallback _callback;

  _ExternalAuthPageState(this._callback);

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(body:
        SafeArea(child:
            Container(padding: EdgeInsets.only(left: 10, right: 10), child: Column(children: [
              Expanded(child: Center(child: Text(
                  context.strings.external_auth_page_search_products_with + " " +
                      context.strings.global_app_name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline5))),
              Expanded(child: Center(child: SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    label: Text(context.strings.external_auth_page_continue_with_google),
                    // icon: Icon(Icons.golf_course_outlined),
                    icon: SizedBox(width: 30, height: 30, child: SvgPicture.asset("assets/google_icon.svg")),
                    onPressed: _onGoogleAuthClicked)))),
            ]))
        )
      );
  }

  void _onGoogleAuthClicked() async {
    final google_account = await GetIt.I.get<GoogleAuthorizer>().auth();
    if (google_account != null) {
      // TODO(https://trello.com/c/tpTEiZpc/): server auth/register
      _callback.call(ExternalAuthResult(googleUser: google_account));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.strings.global_something_went_wrong)));
    }
  }
}
