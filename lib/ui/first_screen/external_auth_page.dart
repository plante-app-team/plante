import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:untitled_vegan_app/base/either_extension.dart';
import 'package:untitled_vegan_app/outside/backend/backend.dart';
import 'package:untitled_vegan_app/l10n/strings.dart';
import 'package:untitled_vegan_app/outside/identity/google_authorizer.dart';
import 'package:untitled_vegan_app/model/user_params.dart';

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
    return
      Scaffold(body:
        SafeArea(child:
            Stack(children: [
              if (_loading) SizedBox(width: double.infinity, child: LinearProgressIndicator()),
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
                      onPressed: !_loading ? _onGoogleAuthClicked : null)))),
              ]))])
        )
      );
  }

  void _onGoogleAuthClicked() async {
    try {
      setState(() {
        _loading = true;
      });

      final googleAccount = await GetIt.I.get<GoogleAuthorizer>().auth();
      if (googleAccount == null) {
        // TODO(https://trello.com/c/XWAE5UVB/): log warning
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.strings.global_something_went_wrong)));
        return;
      }

      final backend = GetIt.I.get<Backend>();
      final loginResult = await backend.loginOrRegister(googleAccount.idToken);
      if (loginResult.isRight) {
        // TODO(https://trello.com/c/XWAE5UVB/): log warning
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.strings.global_something_went_wrong)));
        return;
      }

      _callback.call(loginResult.requireLeft());
    } finally {
      setState(() { _loading = false; });
    }
  }
}
