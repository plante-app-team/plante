import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/lang/user_langs_manager.dart';
import 'package:plante/lang/user_langs_manager_error.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/user_langs.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/user_avatar_manager.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/stepper/customizable_stepper.dart';
import 'package:plante/ui/base/stepper/stepper_page.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/langs/user_langs_widget.dart';
import 'package:plante/ui/profile/components/edit_user_data_widget.dart';

typedef UserParamsSpecifiedCallback = Future<bool> Function(
    UserParams userParams);

class InitUserPage extends PagePlante {
  const InitUserPage({Key? key}) : super(key: key);

  @override
  _InitUserPageState createState() => _InitUserPageState();
}

class _InitUserPageState extends PageStatePlante<InitUserPage> {
  bool _loading = false;

  late final EditUserDataWidgetController _editUserDataController;

  final _userParamsController = GetIt.I.get<UserParamsController>();
  final _userLangsManager = GetIt.I.get<UserLangsManager>();
  final _backend = GetIt.I.get<Backend>();
  final _avatarManager = GetIt.I.get<UserAvatarManager>();
  UserLangs? _userLangs;

  final _stepperController = CustomizableStepperController();

  var _firstPageHasData = false;

  UserParams get _userParams => _editUserDataController.userParams;
  set _userParams(UserParams params) =>
      _editUserDataController.userParams = params;

  Uri? get _userAvatar => _editUserDataController.userAvatar;

  _InitUserPageState() : super('InitUserPage');

  @override
  void initState() {
    super.initState();
    final initialUserParams =
        () async => await _userParamsController.getUserParams() ?? UserParams();
    final initialUserAvatar = () async => await _avatarManager.userAvatarUri();
    _editUserDataController = EditUserDataWidgetController(
        initialUserParams: initialUserParams.call(),
        initialAvatar: initialUserAvatar.call(),
        userAvatarHttpHeaders: _avatarManager.userAvatarAuthHeaders(),
        selectImageFromGallery: _selectImageFromGallery)
      ..registerChangeCallback(_validateFirstPageInputs);
    _initAsync();
  }

  Future<Uri?> _selectImageFromGallery() async {
    return _avatarManager.askUserToSelectImageFromGallery(context,
        iHaveTriedRetrievingLostImage: true);
  }

  void _initAsync() {
    _longAction(() async {
      final lostAvatar =
          await _avatarManager.retrieveLostSelectedAvatar(context);
      if (lostAvatar != null) {
        _editUserDataController.userAvatar = lostAvatar;
      }
      _validateFirstPageInputs();
      _initUserLangs();
    });
  }

  bool _validateFirstPageInputs() {
    final firstPageHasData = _editUserDataController.isDataValid();
    if (firstPageHasData != _firstPageHasData) {
      setState(() {
        _firstPageHasData = firstPageHasData;
      });
    }
    return firstPageHasData;
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
    final content = SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: Column(children: [
              EditUserDataWidget(controller: _editUserDataController),
            ])));

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

        // NOTE: we intentionally update the avatar before
        // user params, because otherwise the InitUserPage widget
        // will be immediately closed after valid user params are set
        // bellow.
        // The code is far from great and should be refactored when
        // there will be a chance.
        if (_userAvatar?.isScheme('FILE') == true) {
          final avatarUploadRes =
              await _avatarManager.updateUserAvatar(_userAvatar!);
          if (avatarUploadRes.isErr) {
            _showError(avatarUploadRes.unwrapErr().convert());
            return;
          }
          _userParams =
              _userParams.rebuild((e) => e.avatarId = avatarUploadRes.unwrap());
        } else if (_userAvatar == null) {
          final avatarDeleteRes = await _avatarManager.deleteUserAvatar();
          if (avatarDeleteRes.isErr) {
            _showError(avatarDeleteRes.unwrapErr().convert());
            return;
          }
          _userParams = _userParams.rebuild((e) => e.avatarId = null);
        }

        // Update on backend
        final paramsRes = await _backend.updateUserParams(_userParams);
        if (paramsRes.isErr) {
          _showError(paramsRes.unwrapErr().convert());
          return;
        }

        // Full local update if server said "ok"
        await _userParamsController.setUserParams(_userParams);
        _userParams = (await _userParamsController.getUserParams())!;

        // Update langs
        final langRes = await _userLangsManager
            .setManualUserLangs(_userLangs!.langs.toList());
        if (langRes.isErr) {
          _showError(langRes.unwrapErr().convert());
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

  void _showError(GeneralError error) {
    if (error == GeneralError.NETWORK) {
      showSnackBar(context.strings.global_network_error, context);
    } else {
      showSnackBar(context.strings.global_something_went_wrong, context);
    }
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

extension on BackendError {
  GeneralError convert() {
    switch (errorKind) {
      case BackendErrorKind.NETWORK_ERROR:
        return GeneralError.NETWORK;
      default:
        return GeneralError.OTHER;
    }
  }
}

extension on UserLangsManagerError {
  GeneralError convert() {
    switch (this) {
      case UserLangsManagerError.NETWORK:
        return GeneralError.NETWORK;
      default:
        return GeneralError.OTHER;
    }
  }
}
