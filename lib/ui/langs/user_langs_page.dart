import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/langs/user_langs_widget.dart';

class UserLangsPage extends StatefulWidget {
  const UserLangsPage({Key? key}) : super(key: key);

  @override
  _UserLangsPageState createState() => _UserLangsPageState();
}

class _UserLangsPageState extends PageStatePlante<UserLangsPage> {
  final UserLangsManager _userLangsManager;
  UserLangs? _initialUserLangs;

  _UserLangsPageState()
      : _userLangsManager = GetIt.I.get<UserLangsManager>(),
        super('UserLangsPage');

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  void _initAsync() async {
    final userLangs = await _userLangsManager.getUserLangs();
    setState(() {
      _initialUserLangs = userLangs;
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    final Widget content;
    if (_initialUserLangs == null) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = UserLangsWidget(
        initialUserLangs: _initialUserLangs!,
        callback: (updatedUserLangs) {
          setState(() {
            _userLangsManager
                .setManualUserLangs(updatedUserLangs.langs.toList());
          });
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: content,
      ),
    );
  }
}
