import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/langs/user_langs_widget.dart';

class UserLangsPage extends PagePlante {
  const UserLangsPage({Key? key}) : super(key: key);

  @override
  _UserLangsPageState createState() => _UserLangsPageState();
}

class _UserLangsPageState extends PageStatePlante<UserLangsPage> {
  final UserLangsManager _userLangsManager;
  UserLangs? _lastStoredLangs;
  UserLangs? _currentLangs;
  bool _loading = true;

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
      _lastStoredLangs = userLangs;
      _currentLangs = userLangs;
      _loading = false;
    });
  }

  @override
  Widget buildPage(BuildContext context) {
    final Widget langsList;
    if (_lastStoredLangs == null) {
      langsList = const Center(child: CircularProgressIndicator());
    } else {
      langsList = UserLangsWidget(
        initialUserLangs: _lastStoredLangs!,
        callback: _onLangsChange,
      );
    }

    return Scaffold(
      body: SafeArea(
          child: Stack(children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          HeaderPlante(
              title: Text(context.strings.settings_page_langs_i_know,
                  style: TextStyles.headline1),
              leftAction: const FabPlante.backBtnPopOnClick()),
          Expanded(child: langsList),
          Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, bottom: 24, top: 8),
              child: SizedBox(
                  width: double.infinity,
                  child: ButtonFilledPlante.withText(
                      context.strings.global_save,
                      onPressed: !_loading && _currentLangs != _lastStoredLangs
                          ? _onSavePress
                          : null))),
        ]),
        AnimatedSwitcher(
            duration: DURATION_DEFAULT,
            child: _loading
                ? const LinearProgressIndicatorPlante()
                : const SizedBox.shrink()),
      ])),
    );
  }

  void _onLangsChange(UserLangs updatedUserLangs) {
    setState(() {
      _currentLangs = updatedUserLangs;
    });
  }

  void _onSavePress() async {
    _longAction(() async {
      final res = await _userLangsManager
          .setManualUserLangs(_currentLangs!.langs.toList());
      if (res.isOk) {
        setState(() {
          _lastStoredLangs = _currentLangs;
        });
      } else {
        if (res.unwrapErr() == UserLangsManagerError.NETWORK) {
          showSnackBar(context.strings.global_network_error, context);
        } else {
          showSnackBar(context.strings.global_something_went_wrong, context);
        }
      }
    });
  }

  void _longAction(dynamic Function() action) async {
    setState(() {
      _loading = true;
    });
    try {
      await action.call();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
