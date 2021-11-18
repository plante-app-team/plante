import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/input_field_plante.dart';
import 'package:plante/ui/base/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/stepper/customizable_stepper.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/langs/user_langs_widget.dart';

typedef UserParamsSpecifiedCallback = Future<bool> Function(
    UserParams userParams);

class InitUserPage extends StatefulWidget {
  static const MIN_NAME_LENGTH = 3;

  const InitUserPage({Key? key}) : super(key: key);

  @override
  _InitUserPageState createState() => _InitUserPageState();
}

class _InitUserPageState extends PageStatePlante<InitUserPage> {
  bool _loading = false;

  UserParams _userParams = UserParams();
  final _userParamsController = GetIt.I.get<UserParamsController>();
  final _userLangsManager = GetIt.I.get<UserLangsManager>();
  final _backend = GetIt.I.get<Backend>();
  UserLangs? _userLangs;

  final _stepperController = CustomizableStepperController();
  final _nameController = TextEditingController();

  var _firstPageHasData = false;

  _InitUserPageState() : super('InitUserPage');

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  void _initAsync() {
    _longAction(() async {
      _userParams = await _userParamsController.getUserParams() ?? UserParams();

      _nameController.text = _userParams.name ?? '';
      _nameController.addListener(() {
        if (_validateFirstPageInputs()) {
          _userParams =
              _userParams.rebuild((v) => v.name = _nameController.text);
        }
      });

      _validateFirstPageInputs();
      _initUserLangs();
    });
  }

  bool _validateFirstPageInputs() {
    final firstPageHasData = _calcFirstPageHasData();
    if (firstPageHasData != _firstPageHasData) {
      setState(() {
        _firstPageHasData = firstPageHasData;
      });
    }
    return firstPageHasData;
  }

  bool _calcFirstPageHasData() {
    return InitUserPage.MIN_NAME_LENGTH <= _nameController.text.trim().length;
  }

  void _initUserLangs() async {
    final userLangs = await _userLangsManager.getUserLangs();
    if (mounted) {
      setState(() {
        _userLangs = userLangs;
      });
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Stack(children: [
          AnimatedSwitcher(
              duration: DURATION_DEFAULT,
              child: _loading
                  ? const LinearProgressIndicatorPlante()
                  : const SizedBox.shrink()),
          CustomizableStepper(
            pages: [
              _page1(),
              _page2(),
            ],
            controller: _stepperController,
          )
        ])));
  }

  StepperPage _page1() {
    final content = Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Column(children: [
          Expanded(
            child: Stack(children: [
              Center(
                  child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 132),
                          child: Text(context.strings.init_user_page_title,
                              style: TextStyles.headline1)))),
              Center(
                  child: InputFieldPlante(
                key: const Key('name'),
                textCapitalization: TextCapitalization.sentences,
                label: context.strings.init_user_page_name_field_title,
                controller: _nameController,
              ))
            ]),
          ),
        ]));

    final onNextPressed = () {
      FocusScope.of(context).unfocus();
      _stepperController.stepForward();
    };

    final buttonNext = Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: SizedBox(
            width: double.infinity,
            child: ButtonFilledPlante.withText(
                context.strings.init_user_page_next_button_title,
                onPressed:
                    _firstPageHasData && !_loading ? onNextPressed : null)));

    final bottomControls =
        Padding(padding: const EdgeInsets.only(bottom: 24), child: buttonNext);

    return StepperPage(content, bottomControls);
  }

  StepperPage _page2() {
    final Widget content;
    if (_userLangs != null) {
      content = Column(children: [
        Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: Text(context.strings.init_user_page_langs_explanation,
                style: TextStyles.headline4)),
        const SizedBox(height: 17),
        Expanded(
            child: UserLangsWidget(
                initialUserLangs: _userLangs!,
                callback: (newUserLangs) => _userLangs = newUserLangs)),
      ]);
    } else {
      content = const CircularProgressIndicator();
    }

    final onDoneClicked = () async {
      _longAction(() async {
        Log.i('InitUserPage, onDoneClicked: $_userParams');

        // Update on backend
        final paramsRes = await _backend.updateUserParams(_userParams);
        if (paramsRes.isErr) {
          if (paramsRes.unwrapErr().errorKind ==
              BackendErrorKind.NETWORK_ERROR) {
            showSnackBar(context.strings.global_network_error, context);
          } else {
            showSnackBar(context.strings.global_something_went_wrong, context);
          }
          return;
        }

        // Full local update if server said "ok"
        await _userParamsController.setUserParams(_userParams);
        _userParams = (await _userParamsController.getUserParams())!;

        // Update langs
        final langRes = await _userLangsManager
            .setManualUserLangs(_userLangs!.langs.toList());
        if (langRes.isErr) {
          if (langRes.unwrapErr() == UserLangsManagerError.NETWORK) {
            showSnackBar(context.strings.global_network_error, context);
          } else {
            showSnackBar(context.strings.global_something_went_wrong, context);
          }
          return;
        }
        _userParams = langRes.unwrap();
      });
    };

    final buttonDone = Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: SizedBox(
            width: double.infinity,
            child: ButtonFilledPlante.withText(
                context.strings.init_user_page_done_button_title,
                onPressed:
                    !_loading && _userLangs != null ? onDoneClicked : null)));

    final bottomControls =
        Padding(padding: const EdgeInsets.only(bottom: 24), child: buttonDone);

    return StepperPage(content, bottomControls);
  }

  void _longAction(Future<void> Function() action) async {
    try {
      setState(() {
        _loading = true;
      });
      await action.call();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}
